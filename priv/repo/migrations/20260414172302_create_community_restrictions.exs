defmodule Atlas.Repo.Migrations.CreateCommunityRestrictions do
  use Ecto.Migration

  def change do
    create table(:community_restrictions) do
      add :reason, :text
      add :community_id, references(:communities, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :restricted_by_id, references(:users, on_delete: :nilify_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:community_restrictions, [:community_id, :user_id])
    create index(:community_restrictions, [:user_id])
    create index(:community_restrictions, [:restricted_by_id])
  end
end
