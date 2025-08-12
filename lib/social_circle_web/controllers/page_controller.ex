defmodule SocialCircleWeb.PageController do
  use SocialCircleWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
