defmodule ErlnoteWeb.Schema.BoardsTypes do
  use Absinthe.Schema.Notation

  object :board do
    field :id, :id
    field :text, :string
    field :title, :string
  end

  input_object :update_board_input do
    field :id, non_null(:id)
    field :text, :string
    field :title, non_null(:string)
  end

  enum :add_board_contributor_filter_type do
    value :id #, as: "id" # Con el "as" se reciben string en lugar de atoms.
    value :username #, as: "username"
  end

  @desc "Filtering options for add contributor"
  input_object :add_board_contributor_filter do
    @desc "ID or USERNAME"
    field :type, non_null(:add_board_contributor_filter_type)
    @desc "String value"
    field :value, non_null(:string)
    @desc "Target board ID"
    field :bid, non_null(:id)
  end

end