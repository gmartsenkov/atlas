defmodule Atlas.Repo.Migrations.RemoveContentFromPages do
  use Ecto.Migration

  def up do
    alter table(:pages) do
      remove :content
    end
  end

  def down do
    alter table(:pages) do
      add :content, :jsonb, default: "[]"
    end
  end
end
