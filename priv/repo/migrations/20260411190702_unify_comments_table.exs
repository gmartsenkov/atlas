defmodule Atlas.Repo.Migrations.UnifyCommentsTable do
  use Ecto.Migration

  def change do
    # Remove FK from reports first
    alter table(:reports) do
      remove :page_comment_id, references(:page_comments, on_delete: :delete_all)
    end

    # Drop old tables
    drop table(:proposal_comments)
    drop table(:page_comments)

    # Create unified comments table
    create table(:comments) do
      add :body, :text, null: false
      add :deleted, :boolean, default: false, null: false
      add :page_id, references(:pages, on_delete: :delete_all)
      add :proposal_id, references(:proposals, on_delete: :delete_all)
      add :author_id, references(:users, on_delete: :delete_all), null: false
      add :parent_id, references(:comments, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:comments, [:page_id, :inserted_at])
    create index(:comments, [:proposal_id, :inserted_at])
    create index(:comments, [:parent_id])
    create index(:comments, [:author_id])

    create constraint(:comments, :comment_must_have_one_parent,
             check:
               "(page_id IS NOT NULL AND proposal_id IS NULL) OR (page_id IS NULL AND proposal_id IS NOT NULL)"
           )

    # Add new FK on reports
    alter table(:reports) do
      add :comment_id, references(:comments, on_delete: :delete_all)
    end

    create index(:reports, [:comment_id])
  end
end
