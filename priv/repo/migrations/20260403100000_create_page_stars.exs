defmodule Atlas.Repo.Migrations.CreatePageStars do
  use Ecto.Migration

  def change do
    create table(:page_stars) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :page_id, references(:pages, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:page_stars, [:user_id, :page_id])
    create index(:page_stars, [:page_id])
  end
end
