defmodule ErlnoteWeb.Authentication do
  @user_salt "Este es el bit que colmo el buffer"

  def sign(data) do
    Phoenix.Token.sign(ErlnoteWeb.Endpoint, @user_salt, data)
  end

  # {:ok, id}
  # {:error, :expired}
  # {:error, :invalid}
  def verify(token) do
    Phoenix.Token.verify(ErlnoteWeb.Endpoint, @user_salt, token, [max_age: 24 * 3600])
  end
end