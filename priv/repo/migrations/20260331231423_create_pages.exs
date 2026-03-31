defmodule Atlas.Repo.Migrations.CreatePages do
  use Ecto.Migration

  def change do
    create table(:pages) do
      add :title, :string, null: false
      add :slug, :string, null: false
      add :content, :jsonb, default: "[]"
      add :community_id, references(:communities, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:pages, [:community_id])
    create unique_index(:pages, [:community_id, :slug])
  end
end
