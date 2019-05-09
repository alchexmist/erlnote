defmodule ErlnoteWeb.Schema.Query.UsersTest do
  use ErlnoteWeb.ConnCase, async: true

  setup do
    Erlnote.Seeds.run()
  end

  @query """
  {
    users {
      name
      username
    }
  }
  """

  test "users field returns users" do
    conn = build_conn()
    conn = get conn, "/api", query: @query
    assert json_response(conn, 200) == %{
      "data" => %{
        "users" => [
          %{"name" => "asm", "username" => "asm"},
          %{"name" => "jsg", "username" => "jsg"},
          %{"name" => "mnmc", "username" => "mnmc"}
        ]
      }
    }
  end

end
