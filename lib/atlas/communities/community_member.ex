defmodule Atlas.Communities.CommunityMember do
  use Ecto.Schema
  import Ecto.Changeset

  schema "community_members" do
    belongs_to :user, Atlas.Accounts.User
    belongs_to :community, Atlas.Communities.Community

    timestamps()
  end

  def changeset(member, attrs) do
    member
    |> cast(attrs, [:user_id, :community_id])
    |> validate_required([:user_id, :community_id])
    |> unique_constraint([:user_id, :community_id])
  end
end
