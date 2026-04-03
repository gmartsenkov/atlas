defmodule Atlas.Repo.Migrations.CreatePageComments do
  use Ecto.Migration

  def change do
    create table(:page_comments) do
      add :body, :text, null: false
      add :page_id, references(:pages, on_delete: :delete_all), null: false
      add :author_id, references(:users, on_delete: :delete_all), null: false
      add :parent_id, references(:page_comments, on_delete: :delete_all)

      timestamps()
    end

    create index(:page_comments, [:page_id, :inserted_at])
    create index(:page_comments, [:parent_id])
  end
end
