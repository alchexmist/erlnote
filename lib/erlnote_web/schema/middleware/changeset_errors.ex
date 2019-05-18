defmodule ErlnoteWeb.Schema.Middleware.ChangesetErrors do
  @behaviour Absinthe.Middleware

  import Ecto.Changeset, only: [traverse_errors: 2]

  def call(resolution_struct, description) do
    # resolution_struct(%Absinthe.Resolution{}): Info about the field that's being resolved.
    with (
      %{errors: [%Ecto.Changeset{} = c]} <- resolution_struct
    ) do
      # One or more errors for a field can be returned in a single `{:error, error_value}` tuple.
      # `error_value` can be:
      # - A simple error message string.
      # - A map containing `:message` key, plus any additional serializable metadata.
      # - A keyword list containing a `:message` key, plus any additional serializable metadata.
      # - A list containing multiple of any/all of these.
      # - Any other value compatible with `to_string/1`.
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