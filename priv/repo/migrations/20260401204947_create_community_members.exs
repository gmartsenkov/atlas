defmodule Atlas.Repo.Migrations.CreateCommunityMembers do
  use Ecto.Migration

  def change do
    create table(:community_members) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :community_id, references(:communities, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:community_members, [:user_id, :community_id])
    create index(:community_members, [:community_id])
  end
end
