defmodule Atlas.Repo.Migrations.AddOwnerToPages do
  use Ecto.Migration

  def change do
    alter table(:pages) do
      add :owner_id, references(:users, on_delete: :nilify_all)
    end

    create index(:pages, [:owner_id])
  end
end
