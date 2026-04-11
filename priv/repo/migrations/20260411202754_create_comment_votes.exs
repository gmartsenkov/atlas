defmodule Atlas.Repo.Migrations.CreateCommentVotes do
  use Ecto.Migration

  def change do
    create table(:comment_votes) do
      add :value, :integer, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :comment_id, references(:comments, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:comment_votes, [:user_id, :comment_id])
    create index(:comment_votes, [:comment_id])

    create constraint(:comment_votes, :valid_vote_value, check: "value = 1 OR value = -1")
  end
end
