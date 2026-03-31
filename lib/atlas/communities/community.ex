defmodule Atlas.Communities.Community do
  use Ecto.Schema
  import Ecto.Changeset

  schema "communities" do
    field :name, :string
    field :slug, :string
    field :description, :string

    has_many :pages, Atlas.Communities.Page

    timestamps()
  end

  def changeset(community, attrs) do
    community
    |> cast(attrs, [:name, :slug, :description])
    |> validate_required([:name, :slug])
    |> validate_format(:slug, ~r/^[a-z0-9]+(?:-[a-z0-9]+)*$/, message: "must be lowercase with hyphens")
    |> unique_constraint(:slug)
  end
end
