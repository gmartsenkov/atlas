defmodule Atlas.Repo.Migrations.AddSortOrderToPages do
  use Ecto.Migration

  def change do
    alter table(:pages) do
      add :sort_order, :integer, default: 0, null: false
    end
  end
end
