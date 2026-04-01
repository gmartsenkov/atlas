defmodule Atlas.Repo.Migrations.RemoveSlugFromCommunities do
  use Ecto.Migration

  def change do
    drop index(:communities, [:slug])

    alter table(:communities) do
      remove :slug, :string
    end

    create unique_index(:communities, [:name])
  end
end
