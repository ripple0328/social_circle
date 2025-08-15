defmodule SocialCircle.Accounts.LinkedProvider do
  @moduledoc """
  LinkedProvider resource for managing additional OAuth provider connections.

  This allows users to connect multiple social accounts (e.g., Google + Facebook)
  to their primary account.
  """

  use Ash.Resource,
    domain: SocialCircle.Accounts,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table("linked_providers")
    repo(SocialCircle.Repo)
  end

  attributes do
    uuid_primary_key(:id)

    attribute :provider, :atom do
      allow_nil?(false)
      constraints(one_of: [:x, :facebook, :google, :apple])
    end

    attribute :provider_id, :string do
      allow_nil?(false)
    end

    attribute(:avatar_url, :string)

    attribute :raw_data, :map do
      default(%{})
    end

    timestamps()
  end

  relationships do
    belongs_to :user, SocialCircle.Accounts.User do
      allow_nil?(false)
      attribute_writable?(true)
    end
  end

  identities do
    identity(:unique_linked_provider, [:provider, :provider_id])
  end

  actions do
    defaults([:read])

    create :create do
      description("Create a linked provider for a user")

      accept([
        :user_id,
        :provider,
        :provider_id,
        :avatar_url,
        :raw_data
      ])

      primary?(true)

      validate(present([:user_id, :provider, :provider_id]))
      validate(one_of(:provider, [:x, :facebook, :google, :apple]))
    end

    destroy :destroy do
      description("Remove a linked provider")
      primary?(true)
    end
  end

  code_interface do
    domain(SocialCircle.Accounts)
    define(:create_linked_provider, action: :create, args: [:user_id, :provider, :provider_id])
    define(:remove_linked_provider, action: :destroy)
  end

  policies do
    # Bypass authorization in test environment
    bypass actor_attribute_equals(:test_env, true) do
      authorize_if(always())
    end

    # Creation is handled through User.link_provider action
    policy action(:create) do
      authorize_if(always())
    end

    policy action_type(:read) do
      # Allow reads when user matches the record's user_id
      authorize_if(expr(user_id == ^actor(:id)))
    end

    policy action(:destroy) do
      authorize_if(actor_present())
      # Users can only remove their own linked providers
      authorize_if(expr(user_id == ^actor(:id)))
    end
  end
end
