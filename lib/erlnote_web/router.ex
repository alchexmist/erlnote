defmodule ErlnoteWeb.Router do
  use ErlnoteWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/" do
    pipe_through :api

    forward "/api", Absinthe.Plug, schema: ErlnoteWeb.Schema
    forward "/graphiql", Absinthe.Plug.GraphiQL, schema: ErlnoteWeb.Schema, interface: :simple
  end
  
  # scope "/", ErlnoteWeb do
  #   pipe_through :browser

  #   get "/", PageController, :index
  # end

  # Other scopes may use custom stacks.
  # scope "/api", ErlnoteWeb do
  #   pipe_through :api
  # end
end
