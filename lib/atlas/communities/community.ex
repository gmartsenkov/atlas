defmodule Atlas.Communities.Community do
  use Ecto.Schema
  import Ecto.Changeset

  schema "communities" do
    field :name, :string
    field :slug, :string
    field :description, :string
    field :icon, :string
    field :member_count, :integer, virtual: true, default: 0

    belongs_to :owner, Atlas.Accounts.User
    has_many :pages, Atlas.Communities.Page
    has_many :community_members, Atlas.Communities.CommunityMember
    has_many :members, through: [:community_members, :user]

    timestamps()
  end

  def changeset(community, attrs) do
    community
    |> cast(attrs, [:name, :slug, :description, :icon, :owner_id])
    |> validate_required([:name, :slug])
    |> validate_format(:slug, ~r/^[a-z0-9]+(?:-[a-z0-9]+)*$/,
      message: "must be lowercase with hyphens"
    )
    |> unique_constraint(:slug)
    |> foreign_key_constraint(:owner_id)
  end
end
