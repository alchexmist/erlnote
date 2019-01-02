defmodule Erlnote.Repo do
  use Ecto.Repo,
    otp_app: :erlnote,
    adapter: Ecto.Adapters.Postgres
end
