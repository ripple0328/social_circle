defmodule SocialCircle.Repo do
  use Ecto.Repo,
    otp_app: :social_circle,
    adapter: Ecto.Adapters.Postgres
end
