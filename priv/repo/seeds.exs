# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Erlnote.Repo.insert!(%Erlnote.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
alias Erlnote.Repo
alias Erlnote.Accounts.User

Repo.insert!(
    User.registration_changeset(
        %User{},
        %{
            username: "asm", 
            name: "asm", 
            credential: %{ 
                email: "asm@example.com", 
                password: "altosecreto"
            }
        }
    )
)