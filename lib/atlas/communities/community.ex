defmodule Atlas.Communities.Community do
  use Ecto.Schema
  import Ecto.Changeset

  schema "communities" do
    field :name, :string
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
    |> cast(attrs, [:name, :description, :icon, :owner_id])
    |> validate_required([:name, :description])
    |> validate_format(:name, ~r/^[a-zA-Z0-9_]+$/,
      message: "can only contain letters, numbers, and underscores"
    )
    |> unique_constraint(:name)
    |> foreign_key_constraint(:owner_id)
  end

  def edit_changeset(community, attrs) do
    community
    |> cast(attrs, [:description, :icon])
    |> validate_required([:description])
  end
end
