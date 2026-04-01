defmodule Atlas.Repo.Migrations.AddIconToCommunities do
  use Ecto.Migration

  def change do
    alter table(:communities) do
      add :icon, :string
    end
  end
end
