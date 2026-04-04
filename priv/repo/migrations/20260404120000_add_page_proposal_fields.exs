defmodule Atlas.Repo.Migrations.AddPageProposalFields do
  use Ecto.Migration

  def change do
    alter table(:proposals) do
      modify :section_id, :bigint, null: true, from: {:bigint, null: false}
      add :community_id, references(:communities, on_delete: :delete_all), null: true
      add :proposed_slug, :string, null: true
      add :collection_id, references(:collections, on_delete: :nilify_all), null: true
    end

    create index(:proposals, [:community_id, :status])
  end
end
