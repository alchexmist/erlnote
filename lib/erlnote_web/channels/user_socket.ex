defmodule ErlnoteWeb.UserSocket do
  use Phoenix.Socket
  use Absinthe.Phoenix.Socket, schema: ErlnoteWeb.Schema
  
  ## Channels
  # channel "room:*", ErlnoteWeb.RoomChannel

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  # def connect(_params, socket, _connect_info) do
  #   {:ok, socket}
  # end

  # Client sends token without "Bearer ". 
  # ws://localhost:4000/socket?token=hello
  def connect(%{"token" => token} = _params, socket, _connect_info) do
    IO.inspect token
    case c = gen_context(token) do
      %{current_user: _} ->
        socket = Absinthe.Phoenix.Socket.put_options(socket, context: c)
        {:ok, socket}
      _ -> :error
    end
  end

  def connect(_params, _socket, _connect_info) do
    :error
  end

  defp gen_context(token) do
    with(
      {:ok, data} <- ErlnoteWeb.Authentication.verify(token),
      %{} = user <- get_user(data)
    ) do
      %{current_user: user}
    else
      _ -> :error
    end
  end

  defp get_user(%{id: id}) do
    Erlnote.Accounts.get_user_by_id(id)
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     ErlnoteWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  def id(_socket), do: nil
end
