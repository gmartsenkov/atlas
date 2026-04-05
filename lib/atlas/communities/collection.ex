defmodule Atlas.Communities.Collection do
  use Ecto.Schema
  import Ecto.Changeset

  schema "collections" do
    field :name, :string
    field :sort_order, :integer, default: 0

    belongs_to :community, Atlas.Communities.Community
    has_many :pages, Atlas.Communities.Page

    timestamps()
  end

  def changeset(collection, attrs) do
    collection
    |> cast(attrs, [:name, :sort_order, :community_id])
    |> validate_required([:name, :community_id])
    |> validate_length(:name, min: 1, max: 100)
    |> foreign_key_constraint(:community_id)
    |> unique_constraint([:community_id, :name],
      error_key: :name,
      message: "already exists in this community"
    )
  end
end
