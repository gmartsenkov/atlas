defmodule Atlas.Repo.Migrations.AddReportedUserToReports do
  use Ecto.Migration

  def change do
    alter table(:reports) do
      add :reported_user_id, references(:users, on_delete: :nilify_all)
      modify :community_id, :bigint, null: true, from: {:bigint, null: false}
    end

    create index(:reports, [:reported_user_id])
  end
end
