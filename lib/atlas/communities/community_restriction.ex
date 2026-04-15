defmodule Atlas.Communities.CommunityRestriction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "community_restrictions" do
    field :reason, :string

    belongs_to :community, Atlas.Communities.Community
    belongs_to :user, Atlas.Accounts.User
    belongs_to :restricted_by, Atlas.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(restriction, attrs) do
    restriction
    |> cast(attrs, [:reason, :community_id, :user_id, :restricted_by_id])
    |> validate_required([:community_id, :user_id, :restricted_by_id])
    |> foreign_key_constraint(:community_id)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:restricted_by_id)
    |> unique_constraint([:community_id, :user_id],
      message: "user is already restricted in this community"
    )
  end
end
