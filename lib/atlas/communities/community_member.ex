defmodule Atlas.Communities.CommunityMember do
  use Ecto.Schema
  import Ecto.Changeset

  schema "community_members" do
    field :role, :string, default: "member"
    belongs_to :user, Atlas.Accounts.User
    belongs_to :community, Atlas.Communities.Community

    timestamps(type: :utc_datetime)
  end

  def changeset(member, attrs) do
    member
    |> cast(attrs, [:user_id, :community_id])
    |> validate_required([:user_id, :community_id])
    |> unique_constraint([:user_id, :community_id])
  end

  def role_changeset(member, attrs) do
    member
    |> cast(attrs, [:role])
    |> validate_required([:role])
    |> validate_inclusion(:role, ~w(member moderator))
    |> check_constraint(:role, name: :role_must_be_valid)
  end
end
