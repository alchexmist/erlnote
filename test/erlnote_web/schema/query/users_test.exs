defmodule ErlnoteWeb.Schema.Query.UsersTest do
  # ErlnoteWeb.Schema.Query.UsersTest sets async: true which means that this test case
  # will be run in parallel with other test cases. While individual tests
  # within the case still run serially, this can greatly increase overall
  # test speeds. It is possible to encounter strange behavior with
  # asynchronous tests, but thanks to the Ecto.Adapters.SQL.Sandbox, async
  # tests involving a database can be done without worry. This means that
  # the vast majority of tests in your Phoenix application will be able to
  # be run asynchronously.
  use ErlnoteWeb.ConnCase, async: true

  @query """
  {
    users {
      name
    }
  }
  """
end
