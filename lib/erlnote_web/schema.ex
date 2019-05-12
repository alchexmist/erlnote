defmodule ErlnoteWeb.Schema do
    use Absinthe.Schema

    import_types __MODULE__.AccountsTypes

    query do
      import_fields :accounts_queries
    end

    

end