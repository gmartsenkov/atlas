defmodule Atlas.Repo.Migrations.CreateCommunities do
  use Ecto.Migration

  def change do
    create table(:communities) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :description, :text

      timestamps()
    end

    create unique_index(:communities, [:slug])
  end
end
