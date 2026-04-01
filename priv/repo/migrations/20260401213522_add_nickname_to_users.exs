defmodule Atlas.Repo.Migrations.AddNicknameToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :nickname, :citext, null: false, default: ""
    end

    create unique_index(:users, [:nickname])

    # Remove the default so future inserts must provide a nickname
    alter table(:users) do
      modify :nickname, :citext, null: false, default: nil
    end
  end
end
