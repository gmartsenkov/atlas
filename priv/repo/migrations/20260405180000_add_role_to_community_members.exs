defmodule Atlas.Repo.Migrations.AddRoleToCommunityMembers do
  use Ecto.Migration

  def change do
    alter table(:community_members) do
      add :role, :string, null: false, default: "member"
    end

    create constraint(:community_members, :role_must_be_valid,
             check: "role IN ('member', 'moderator')"
           )

    create index(:community_members, [:community_id, :role])
  end
end
