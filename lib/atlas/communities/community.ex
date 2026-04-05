defmodule Atlas.Communities.Community do
  use Ecto.Schema
  import Ecto.Changeset

  schema "communities" do
    field :name, :string
    field :description, :string
    field :icon, :string
    field :suggestions_enabled, :boolean, default: true
    field :member_count, :integer, virtual: true, default: 0

    belongs_to :owner, Atlas.Accounts.User
    has_many :pages, Atlas.Communities.Page
    has_many :collections, Atlas.Communities.Collection
    has_many :community_members, Atlas.Communities.CommunityMember
    has_many :members, through: [:community_members, :user]

    timestamps(type: :utc_datetime)
  end

  def changeset(community, attrs) do
    community
    |> cast(attrs, [:name, :description, :icon, :owner_id, :suggestions_enabled])
    |> validate_required([:name, :description])
    |> validate_length(:name, min: 1, max: 50)
    |> validate_length(:description, max: 2000)
    |> validate_format(:name, ~r/^[a-zA-Z0-9_]+$/,
      message: "can only contain letters, numbers, and underscores"
    )
    |> validate_icon_url()
    |> unique_constraint(:name)
    |> foreign_key_constraint(:owner_id)
  end

  def edit_changeset(community, attrs) do
    community
    |> cast(attrs, [:description, :icon, :suggestions_enabled])
    |> validate_required([:description])
    |> validate_length(:description, max: 2000)
    |> validate_icon_url()
  end

  defp validate_icon_url(changeset) do
    changeset
    |> validate_length(:icon, max: 500)
    |> validate_change(:icon, fn :icon, url ->
      case URI.parse(url) do
        %{scheme: scheme} when scheme in ~w(http https) -> []
        _ -> [icon: "must be an http or https URL"]
      end
    end)
  end
end
