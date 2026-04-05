defmodule Atlas.Repo.Migrations.AddPerformanceIndexes do
  use Ecto.Migration

  def change do
    # Partial index for the most common proposal query: counting/listing pending proposals
    create index(:proposals, [:status], where: "status = 'pending'", name: :proposals_pending_idx)

    # User's community memberships lookup (e.g., user profile "my communities")
    create index(:community_members, [:user_id])

    # Proposal comments ordered by insertion (used in preload ordering)
    create index(:proposal_comments, [:proposal_id, :inserted_at])
  end
end
