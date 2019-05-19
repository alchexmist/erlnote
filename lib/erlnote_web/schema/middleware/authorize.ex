defmodule ErlnoteWeb.Schema.Middleware.Authorize do
  @behaviour Absinthe.Middleware

  def call(resolution_struct, _arg) do
    with(
      %{current_user: user} <- resolution_struct.context,
      true <- correct?(user)
    ) do
      resolution_struct
    else
      _ ->
        resolution_struct
        |> Absinthe.Resolution.put_result({:error, "unauthorized"})
    end
  end

  defp correct?(%Erlnote.Accounts.User{}), do: true
  defp correct?(_), do: false
end