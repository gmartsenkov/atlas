defmodule Atlas.Communities.Proposal do
  use Ecto.Schema
  import Ecto.Changeset

  schema "proposals" do
    field :status, :string, default: "pending"
    field :proposed_title, :string
    field :proposed_content, {:array, :map}, default: []
    field :proposed_slug, :string
    field :reviewed_at, :utc_datetime

    belongs_to :section, Atlas.Communities.Section
    belongs_to :author, Atlas.Accounts.User
    belongs_to :reviewed_by, Atlas.Accounts.User
    belongs_to :community, Atlas.Communities.Community
    belongs_to :collection, Atlas.Communities.Collection
    has_many :comments, Atlas.Communities.Comment

    timestamps(type: :utc_datetime)
  end

  def changeset(proposal, attrs) do
    proposal
    |> cast(attrs, [:proposed_title, :proposed_content, :section_id, :author_id])
    |> validate_required([:section_id, :author_id])
    |> foreign_key_constraint(:section_id)
    |> foreign_key_constraint(:author_id)
  end

  def page_proposal_changeset(proposal, attrs) do
    proposal
    |> cast(attrs, [
      :proposed_title,
      :proposed_content,
      :proposed_slug,
      :community_id,
      :collection_id,
      :author_id
    ])
    |> validate_required([:proposed_title, :proposed_slug, :community_id, :author_id])
    |> validate_length(:proposed_title, min: 1, max: 255)
    |> validate_length(:proposed_slug, min: 1, max: 100)
    |> validate_format(:proposed_slug, ~r/^[a-z0-9]+(?:-[a-z0-9]+)*$/,
      message: "must be lowercase with hyphens"
    )
    |> foreign_key_constraint(:community_id)
    |> foreign_key_constraint(:collection_id)
    |> foreign_key_constraint(:author_id)
  end

  def edit_changeset(proposal, attrs) do
    proposal
    |> cast(attrs, [:proposed_title, :proposed_content])
  end

  def edit_page_proposal_changeset(proposal, attrs) do
    proposal
    |> cast(attrs, [:proposed_title, :proposed_content, :proposed_slug, :collection_id])
    |> validate_required([:proposed_title, :proposed_slug])
    |> validate_length(:proposed_title, min: 1, max: 255)
    |> validate_length(:proposed_slug, min: 1, max: 100)
    |> validate_format(:proposed_slug, ~r/^[a-z0-9]+(?:-[a-z0-9]+)*$/,
      message: "must be lowercase with hyphens"
    )
    |> foreign_key_constraint(:collection_id)
  end

  def review_changeset(proposal, attrs) do
    proposal
    |> cast(attrs, [:status, :reviewed_by_id, :reviewed_at])
    |> validate_required([:status, :reviewed_by_id, :reviewed_at])
    |> validate_inclusion(:status, ["approved", "rejected"])
    |> check_constraint(:status, name: :status_must_be_valid)
  end

  def new_page_proposal?(%__MODULE__{section_id: nil, community_id: cid}) when not is_nil(cid),
    do: true

  def new_page_proposal?(_), do: false
end
