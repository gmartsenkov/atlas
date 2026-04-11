defmodule Atlas.Repo.Migrations.AddDeletedToPageComments do
  use Ecto.Migration

  def change do
    alter table(:page_comments) do
      add :deleted, :boolean, default: false, null: false
    end
  end
end
