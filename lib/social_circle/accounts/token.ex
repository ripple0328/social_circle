defmodule SocialCircle.Accounts.Token do
  @moduledoc """
  Token resource for AshAuthentication token storage.
  """

  use Ash.Resource,
    domain: SocialCircle.Accounts,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication.TokenResource]

  postgres do
    table "auth_tokens"
    repo SocialCircle.Repo
  end
end