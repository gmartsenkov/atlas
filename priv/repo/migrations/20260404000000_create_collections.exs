defmodule Atlas.Repo.Migrations.CreateCollections do
  use Ecto.Migration

  def change do
    create table(:collections) do
      add :name, :string, null: false
      add :sort_order, :integer, default: 0, null: false
      add :community_id, references(:communities, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:collections, [:community_id])
    create unique_index(:collections, [:community_id, :name])

    alter table(:pages) do
      add :collection_id, references(:collections, on_delete: :nilify_all)
    end

    create index(:pages, [:collection_id])
  end
end
