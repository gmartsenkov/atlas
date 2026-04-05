defmodule Atlas.Communities.ProposalComment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "proposal_comments" do
    field :body, :string

    belongs_to :proposal, Atlas.Communities.Proposal
    belongs_to :author, Atlas.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:body, :proposal_id, :author_id])
    |> validate_required([:body, :proposal_id, :author_id])
    |> validate_length(:body, min: 1, max: 2000)
    |> foreign_key_constraint(:proposal_id)
    |> foreign_key_constraint(:author_id)
  end
end
