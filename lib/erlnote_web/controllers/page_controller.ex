defmodule ErlnoteWeb.PageController do
  use ErlnoteWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
