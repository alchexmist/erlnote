defmodule ErlnoteWeb.Schema.NotesTypes do
  use Absinthe.Schema.Notation

  object :note do
    field :id, :id
    field :body, :string
    field :title, :string
  end

  input_object :update_note_input do
    field :id, non_null(:id)
    field :body, :string
    field :title, non_null(:string)
  end

  enum :add_note_contributor_filter_type do
    value :id #, as: "id" # Con el "as" se reciben string en lugar de atoms.
    value :username #, as: "username"
  end

  @desc "Filtering options for add contributor"
  input_object :add_note_contributor_filter do
    @desc "ID or USERNAME"
    field :type, non_null(:add_note_contributor_filter_type)
    @desc "String value"
    field :value, non_null(:string)
    @desc "Target note ID"
    field :nid, non_null(:id)
    @desc "Can read?"
    field :can_read, non_null(:boolean)
    @desc "Can write?"
    field :can_write, non_null(:boolean)
  end

end