defmodule SocialCircle.Accounts do
  @moduledoc """
  The Accounts context API using Ash Framework.
  
  This module provides the interface for user authentication, authorization,
  and account management using social OAuth providers.
  """

  use Ash.Domain

  alias SocialCircle.Accounts.{User, LinkedProvider, Token}

  resources do
    resource User
    resource LinkedProvider
    resource Token
  end
end