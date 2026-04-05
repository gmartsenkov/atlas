defmodule Atlas.Repo.Migrations.AddMissingIndexes do
  use Ecto.Migration

  def change do
    create index(:proposals, [:author_id])
    create index(:proposals, [:reviewed_by_id])
    create index(:proposals, [:collection_id])
    create index(:proposal_comments, [:author_id])
    create index(:page_comments, [:author_id])
  end
end
