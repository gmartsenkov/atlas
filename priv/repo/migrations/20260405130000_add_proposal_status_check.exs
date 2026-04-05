defmodule Atlas.Repo.Migrations.AddProposalStatusCheck do
  use Ecto.Migration

  def change do
    create constraint(:proposals, :status_must_be_valid,
             check: "status IN ('pending', 'approved', 'rejected')"
           )
  end
end
