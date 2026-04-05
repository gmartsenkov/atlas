defmodule Atlas.Communities.PageComment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "page_comments" do
    field :body, :string

    belongs_to :page, Atlas.Communities.Page
    belongs_to :author, Atlas.Accounts.User
    belongs_to :parent, Atlas.Communities.PageComment

    has_many :replies, Atlas.Communities.PageComment,
      foreign_key: :parent_id,
      preload_order: [asc: :inserted_at]

    timestamps(type: :utc_datetime)
  end

  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:body, :page_id, :author_id, :parent_id])
    |> validate_required([:body, :page_id, :author_id])
    |> validate_length(:body, min: 1, max: 2000)
    |> foreign_key_constraint(:page_id)
    |> foreign_key_constraint(:author_id)
    |> foreign_key_constraint(:parent_id)
  end
end
