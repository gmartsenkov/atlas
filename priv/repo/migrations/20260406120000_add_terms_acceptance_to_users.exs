defmodule Atlas.Repo.Migrations.AddTermsAcceptanceToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :terms_accepted_at, :utc_datetime
      add :terms_version, :string
    end
  end
end
