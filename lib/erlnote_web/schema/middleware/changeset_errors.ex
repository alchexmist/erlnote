defmodule ErlnoteWeb.Schema.Middleware.ChangesetErrors do
  @behaviour Absinthe.Middleware

  import Ecto.Changeset, only: [traverse_errors: 2]

  def call(resolution_struct, description) do
    # resolution_struct(%Absinthe.Resolution{}): Info about the field that's being resolved.
    with (
      %{errors: [%Ecto.Changeset{} = c]} <- resolution_struct
    ) do
      # %{resolution_struct | value: %{errors: parse_errors(c)}, errors: []}
      #%{resolution_struct | errors: ["Adios"]}
      resolution_struct
      |> Absinthe.Resolution.put_result({:error, message: description, details: parse_errors(c)})
    end
  end
  
  defp parse_errors(%Ecto.Changeset{} = ch) do
    traverse_errors(ch, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    #|> Enum.map(fn {key, value} -> %{key: key, message: value} end)
  end

end