defmodule Erlnote.Helpers.Error do
  import Ecto.Changeset

  def changeset_errors_to_json(%Ecto.Changeset{} = ch) do
    traverse_errors(ch, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Jason.encode!
  end

end