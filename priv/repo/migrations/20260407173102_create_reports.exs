defmodule Atlas.Repo.Migrations.CreateReports do
  use Ecto.Migration

  def change do
    create table(:reports) do
      add :reason, :string, null: false
      add :details, :text
      add :status, :string, null: false, default: "pending"

      add :community_id, references(:communities, on_delete: :delete_all), null: false
      add :page_id, references(:pages, on_delete: :delete_all)
      add :page_comment_id, references(:page_comments, on_delete: :delete_all)
      add :reporter_id, references(:users, on_delete: :nilify_all), null: false
      add :resolved_by_id, references(:users, on_delete: :nilify_all)
      add :resolved_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:reports, [:community_id])
    create index(:reports, [:reporter_id])
    create index(:reports, [:page_id])
    create index(:reports, [:page_comment_id])
    create index(:reports, [:status])

    create constraint(:reports, :valid_reason,
             check:
               "reason IN ('spam', 'harassment', 'misinformation', 'inappropriate', 'copyright', 'other')"
           )

    create constraint(:reports, :valid_status,
             check: "status IN ('pending', 'resolved', 'removed')"
           )
  end
end
