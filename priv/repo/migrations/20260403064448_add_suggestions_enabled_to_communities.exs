defmodule Atlas.Repo.Migrations.AddSuggestionsEnabledToCommunities do
  use Ecto.Migration

  def change do
    alter table(:communities) do
      add :suggestions_enabled, :boolean, default: true, null: false
    end
  end
end
