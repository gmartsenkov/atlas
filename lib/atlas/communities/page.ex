defmodule Atlas.Communities.Page do
  use Ecto.Schema
  import Ecto.Changeset

  schema "pages" do
    field :title, :string
    field :slug, :string
    field :content, {:array, :map}, default: []

    belongs_to :community, Atlas.Communities.Community

    timestamps()
  end

  def changeset(page, attrs) do
    page
    |> cast(attrs, [:title, :slug, :content, :community_id])
    |> validate_required([:title, :slug, :community_id])
    |> validate_format(:slug, ~r/^[a-z0-9]+(?:-[a-z0-9]+)*$/, message: "must be lowercase with hyphens")
    |> foreign_key_constraint(:community_id)
    |> unique_constraint([:community_id, :slug])
  end
end
