defmodule Atlas.Communities.Page do
  use Ecto.Schema
  import Ecto.Changeset

  schema "pages" do
    field :title, :string
    field :slug, :string

    belongs_to :community, Atlas.Communities.Community
    belongs_to :owner, Atlas.Accounts.User

    has_many :sections, Atlas.Communities.Section, preload_order: [asc: :sort_order]

    timestamps()
  end

  def changeset(page, attrs) do
    page
    |> cast(attrs, [:title, :slug, :community_id, :owner_id])
    |> validate_required([:title, :slug, :community_id, :owner_id])
    |> validate_format(:slug, ~r/^[a-z0-9]+(?:-[a-z0-9]+)*$/,
      message: "must be lowercase with hyphens"
    )
    |> foreign_key_constraint(:community_id)
    |> foreign_key_constraint(:owner_id)
    |> unique_constraint([:community_id, :slug],
      error_key: :slug,
      message: "already exists in this community"
    )
  end
end
