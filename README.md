# Erlnote

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Reset your database with `mix ecto.reset`
  * Install Node.js dependencies with `cd assets && npm install`
  * Start Phoenix endpoint with `mix phx.server` or `iex -S mix phx.server`
  * GraphiQL URL: http://localhost:4000/graphiql
  * GraphiQL WS URL: ws://localhost:4000/socket/?token=SFMyNTY.g3QAAAACZAAEZGF0YXQAAAABZAACaWRhAWQABnNpZ25lZG4GADyeCT1rAQ.0A92sxQyR11rV8w4JSeVao8Vkwg1j_AsBD3NxG6HNmU
  
```
mutation {
  login(email: "asm@example.com", password: "altosecreto") {
    token
  }
}
```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Erlnote Frontend
[Link to erlnote-frontend!](https://github.com/alchexmist/erlnote-frontend)

## Learn more

  * Official website: http://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Mailing list: http://groups.google.com/group/phoenix-talk
  * Source: https://github.com/phoenixframework/phoenix
