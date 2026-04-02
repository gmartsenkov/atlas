defmodule Atlas.Communities.Proposal do
  use Ecto.Schema
  import Ecto.Changeset

  schema "proposals" do
    field :status, :string, default: "pending"
    field :proposed_title, :string
    field :proposed_content, {:array, :map}, default: []
    field :reviewed_at, :utc_datetime

    belongs_to :section, Atlas.Communities.Section
    belongs_to :author, Atlas.Accounts.User
    belongs_to :reviewed_by, Atlas.Accounts.User
    has_many :comments, Atlas.Communities.ProposalComment

    timestamps()
  end

  def changeset(proposal, attrs) do
    proposal
    |> cast(attrs, [:proposed_title, :proposed_content, :section_id, :author_id])
    |> validate_required([:section_id, :author_id])
    |> foreign_key_constraint(:section_id)
    |> foreign_key_constraint(:author_id)
  end

  def review_changeset(proposal, attrs) do
    proposal
    |> cast(attrs, [:status, :reviewed_by_id, :reviewed_at])
    |> validate_required([:status, :reviewed_by_id, :reviewed_at])
    |> validate_inclusion(:status, ["approved", "rejected"])
  end
end
