defmodule SocialCircle.Accounts.User do
  @moduledoc """
  User resource for social authentication using Ash Framework.
  
  Users authenticate through social OAuth providers (X, Facebook, Google, Apple)
  and can link multiple accounts to a single profile.
  """

  use Ash.Resource,
    domain: SocialCircle.Accounts,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "users"
    repo SocialCircle.Repo

    references do
      reference :linked_providers, on_delete: :delete
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :email, :string do
      allow_nil? false
      constraints match: ~r/^[^\s]+@[^\s]+\.[^\s]+$/
    end

    attribute :provider, :atom do
      allow_nil? false
      constraints one_of: [:x, :facebook, :google, :apple]
    end

    attribute :provider_id, :string do
      allow_nil? false
    end

    attribute :name, :string
    attribute :avatar_url, :string
    
    attribute :raw_data, :map do
      default %{}
    end

    timestamps()
  end

  relationships do
    has_many :linked_providers, SocialCircle.Accounts.LinkedProvider do
      destination_attribute :user_id
    end
  end

  identities do
    identity :unique_email, [:email]
    identity :unique_provider_account, [:provider, :provider_id]
  end

  calculations do
    calculate :primary_provider, :atom, expr(provider)
    
    calculate :connected_providers, {:array, :atom} do
      calculation fn records, _opts ->
        Enum.map(records, fn record ->
          linked = Ash.load!(record, :linked_providers).linked_providers
          providers = [record.provider | Enum.map(linked, & &1.provider)]
          Enum.uniq(providers)
        end)
      end
    end
  end

  actions do
    defaults [:read]

    create :create_from_oauth do
      description "Create a new user from OAuth provider data"
      
      accept [
        :email,
        :provider,
        :provider_id,
        :name,
        :avatar_url,
        :raw_data
      ]

      primary? true

      validate present([:email, :provider, :provider_id])
      validate match(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/)
      validate one_of(:provider, [:x, :facebook, :google, :apple])
    end

    create :find_or_create_from_oauth do
      description "Find existing user by email or create new one from OAuth data"
      
      accept [
        :email,
        :provider,
        :provider_id,
        :name,
        :avatar_url,
        :raw_data
      ]

      upsert? true
      upsert_identity :unique_email

      validate present([:email, :provider, :provider_id])
    end

    update :link_provider do
      description "Link an additional OAuth provider to existing user"
      
      require_atomic? false

      argument :provider, :atom do
        allow_nil? false
        constraints one_of: [:x, :facebook, :google, :apple]
      end

      argument :provider_id, :string do
        allow_nil? false
      end

      argument :avatar_url, :string

      change fn changeset, _context ->
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
          {:ok, _linked_provider} -> changeset
          {:error, error} -> Ash.Changeset.add_error(changeset, error)
        end
      end
    end

    update :update_profile do
      description "Update user profile information"
      
      accept [:name, :avatar_url]
      
      validate present(:name, message: "Name cannot be blank")
    end
  end

  code_interface do
    domain SocialCircle.Accounts
    define :create_from_oauth, args: [:email, :provider, :provider_id]
    define :find_or_create_from_oauth, args: [:email, :provider, :provider_id]
    define :get_by_email, action: :read, get_by: [:email]
    define :list_users, action: :read
  end

  policies do
    # OAuth creation actions don't require authentication
    policy action_type(:create) do
      authorize_if always()
    end

    policy action_type(:read) do
      authorize_if actor_present()
      # Users can only read their own data
      authorize_if expr(id == ^actor(:id))
    end

    policy action(:update_profile) do
      authorize_if actor_present()
      # Users can only update their own profile
      authorize_if expr(id == ^actor(:id))
    end

    policy action(:link_provider) do
      authorize_if actor_present()
      # Users can only link providers to their own account
      authorize_if expr(id == ^actor(:id))
    end
  end
end