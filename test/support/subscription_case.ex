defmodule ErlnoteWeb.SubscriptionCase do
  @moduledoc """
  This module defines the test case to be used by subscription tests.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      use ErlnoteWeb.ChannelCase
      use Absinthe.Phoenix.SubscriptionTest, schema: ErlnoteWeb.Schema

      setup do
        Erlnote.Seeds.run()

        {:ok, socket} = Phoenix.ChannelTest.connect(ErlnoteWeb.UserSocket, %{})
        {:ok, socket} = Absinthe.Phoenix.SubscriptionTest.join_absinthe(socket)

        {:ok, socket: socket}
      end
    end
  end
end