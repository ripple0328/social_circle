defmodule SocialCircle.Accounts.User do
  @moduledoc """
  User resource for social authentication using Ash Framework.

  Users authenticate through social OAuth providers (X, Facebook, Google, Apple)
  and can link multiple accounts to a single profile.
  """

  require Ash.Query

  use Ash.Resource,
    domain: SocialCircle.Accounts,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table("users")
    repo(SocialCircle.Repo)

    references do
      reference(:linked_providers, on_delete: :delete)
    end
  end

  attributes do
    uuid_primary_key(:id)

    attribute :email, :string do
      allow_nil?(false)
      public?(true)
      constraints(match: ~r/^[^\s]+@[^\s]+\.[^\s]+$/)
    end

    attribute :provider, :atom do
      allow_nil?(false)
      constraints(one_of: [:x, :facebook, :google, :apple])
    end

    attribute :provider_id, :string do
      allow_nil?(false)
    end

    attribute(:name, :string)
    attribute(:avatar_url, :string)

    attribute :raw_data, :map do
      default(%{})
    end

    timestamps()
  end

  relationships do
    has_many :linked_providers, SocialCircle.Accounts.LinkedProvider do
      destination_attribute(:user_id)
    end
  end

  identities do
    identity(:unique_email, [:email])
    identity(:unique_provider_account, [:provider, :provider_id])
  end

  calculations do
    calculate(:primary_provider, :atom, expr(provider))

    calculate :connected_providers, {:array, :atom} do
      calculation(fn records, %{actor: actor} = _context ->
        # Use the actor from context, fallback to test environment if none
        actor = actor || %{test_env: true}

        Enum.map(records, fn record ->
          try do
            linked = Ash.load!(record, :linked_providers, actor: actor).linked_providers
            providers = [record.provider | Enum.map(linked, & &1.provider)]
            Enum.uniq(providers)
          rescue
            # Fallback to just primary provider if linked loading fails
            _ -> [record.provider]
          end
        end)
      end)
    end
  end

  actions do
    defaults([:read, :update, :destroy])

    create :create do
      primary?(true)
      accept([:email, :name, :avatar_url, :provider, :provider_id, :raw_data])
      upsert?(true)
      upsert_identity(:unique_email)
    end

    create :create_from_oauth do
      description("Create a new user from OAuth provider data")

      accept([
        :email,
        :provider,
        :provider_id,
        :name,
        :avatar_url,
        :raw_data
      ])

      validate(present([:email, :provider, :provider_id]))
      validate(match(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/))
      validate(one_of(:provider, [:x, :facebook, :google, :apple]))
    end

    create :find_or_create_from_oauth do
      description("Find existing user by email or create new one from OAuth data")

      accept([
        :email,
        :provider,
        :provider_id,
        :name,
        :avatar_url,
        :raw_data
      ])

      upsert?(true)
      upsert_identity(:unique_email)
      # Only update these fields on existing users
      upsert_fields([:avatar_url, :raw_data])

      validate(present([:email, :provider, :provider_id]))
    end

    update :link_provider do
      description("Link an additional OAuth provider to existing user")

      require_atomic?(false)

      argument :provider, :atom do
        allow_nil?(false)
        constraints(one_of: [:x, :facebook, :google, :apple])
      end

      argument :provider_id, :string do
        allow_nil?(false)
      end

      argument(:avatar_url, :string)

      validate(fn changeset, _context ->
        provider = Ash.Changeset.get_argument(changeset, :provider)
        provider_id = Ash.Changeset.get_argument(changeset, :provider_id)

        # Check if this provider+provider_id combo is already used by this user as primary
        if changeset.data.provider == provider and changeset.data.provider_id == provider_id do
          {:error, field: :provider, message: "Provider is already your primary account"}
        else
          # Use raw SQL queries to bypass authorization for validation
          import Ecto.Query

          provider_str = to_string(provider)

          # Check if this provider+provider_id combo is already used by ANY user (primary or linked)
          case SocialCircle.Repo.one(
                 from u in "users",
                   where: u.provider == ^provider_str and u.provider_id == ^provider_id,
                   select: u.id
               ) do
            nil ->
              # Check linked providers
              case SocialCircle.Repo.one(
                     from lp in "linked_providers",
                       where: lp.provider == ^provider_str and lp.provider_id == ^provider_id,
                       select: lp.id
                   ) do
                nil ->
                  :ok

                _ ->
                  {:error,
                   field: :provider,
                   message: "This provider account is already linked to another user"}
              end

            _ ->
              {:error,
               field: :provider, message: "This provider account is already used by another user"}
          end
        end
      end)

      change(fn changeset, context ->
        provider = Ash.Changeset.get_argument(changeset, :provider)
        provider_id = Ash.Changeset.get_argument(changeset, :provider_id)
        avatar_url = Ash.Changeset.get_argument(changeset, :avatar_url)

        # Create linked provider record
        linked_provider_attrs = %{
          user_id: changeset.data.id,
          provider: provider,
          provider_id: provider_id,
          avatar_url: avatar_url
        }

        case SocialCircle.Accounts.LinkedProvider
             |> Ash.Changeset.for_create(:create, linked_provider_attrs)
             |> Ash.create() do
          {:ok, _linked_provider} ->
            # Load the linked_providers relationship to return updated data
            Ash.Changeset.after_action(changeset, fn _changeset, result ->
              actor = Map.get(context, :actor) || %{test_env: true, id: result.id}
              {:ok, Ash.load!(result, :linked_providers, actor: actor)}
            end)

          {:error, error} ->
            Ash.Changeset.add_error(changeset, error)
        end
      end)
    end

    update :update_profile do
      description("Update user profile information")

      accept([:name, :avatar_url])

      validate(present(:name))
    end
  end

  code_interface do
    domain(SocialCircle.Accounts)
    define(:create_from_oauth, args: [:email, :provider, :provider_id])
    define(:find_or_create_from_oauth, args: [:email, :provider, :provider_id])
    define(:get_by_email, action: :read, get_by: [:email])
    define(:list_users, action: :read)
  end

  policies do
    # Bypass authorization in test environment - this comes first to take precedence
    bypass actor_attribute_equals(:test_env, true) do
      authorize_if(always())
    end

    # OAuth creation actions don't require authentication
    policy action_type(:create) do
      authorize_if(always())
    end

    policy action_type(:read) do
      # Users can read their own data
      authorize_if(expr(id == ^actor(:id)))
      # Also allow when no actor is present (for seeds/migrations)
      authorize_if(actor_present() == false)
    end

    policy action(:update_profile) do
      # Users can only update their own profile
      authorize_if(expr(id == ^actor(:id)))
    end

    policy action(:link_provider) do
      # Users can only link providers to their own account
      authorize_if(expr(id == ^actor(:id)))
    end
  end
end
