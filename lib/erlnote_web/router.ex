defmodule ErlnoteWeb.Router do
  use ErlnoteWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", ErlnoteWeb do
    pipe_through :api
  end
end
