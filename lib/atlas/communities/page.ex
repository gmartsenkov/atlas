defmodule Atlas.Communities.Page do
  use Ecto.Schema
  import Ecto.Changeset

  schema "pages" do
    field :title, :string
    field :slug, :string
    field :sort_order, :integer, default: 0

    belongs_to :community, Atlas.Communities.Community
    belongs_to :owner, Atlas.Accounts.User
    belongs_to :collection, Atlas.Communities.Collection

    has_many :sections, Atlas.Communities.Section, preload_order: [asc: :sort_order]
    has_many :page_stars, Atlas.Communities.PageStar
    has_many :page_comments, Atlas.Communities.PageComment

    timestamps()
  end

  def changeset(page, attrs) do
    page
    |> cast(attrs, [:title, :slug, :community_id, :owner_id, :collection_id, :sort_order])
    |> validate_required([:title, :slug, :community_id, :owner_id])
    |> validate_length(:title, min: 1, max: 255)
    |> validate_length(:slug, min: 1, max: 100)
    |> validate_format(:slug, ~r/^[a-z0-9]+(?:-[a-z0-9]+)*$/,
      message: "must be lowercase with hyphens"
    )
    |> foreign_key_constraint(:community_id)
    |> foreign_key_constraint(:owner_id)
    |> foreign_key_constraint(:collection_id)
    |> unique_constraint([:community_id, :slug],
      error_key: :slug,
      message: "already exists in this community"
    )
  end
end
