defmodule ErlnoteWeb.Context do
  @behaviour Plug
  
  import Plug.Conn

  def init(opts) do
    opts  
  end
  
  def call(conn, _opts) do
    context = gen_context(conn)
    IO.inspect [context: context]
    Absinthe.Plug.put_options(conn, context: context)
  end
  
  defp gen_context(conn) do
    with(
      ["Bearer " <> token] <- get_req_header(conn, "authorization"),
      {:ok, data} <- ErlnoteWeb.Authentication.verify(token),
      %{} = user <- get_user(data)
    ) do
      %{current_user: user}
    else
      _ -> %{}
    end
  end

  defp get_user(%{id: id}) do
    Erlnote.Accounts.get_user_by_id(id)
  end
end