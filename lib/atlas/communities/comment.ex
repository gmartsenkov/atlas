defmodule Atlas.Communities.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "comments" do
    field :body, :string
    field :deleted, :boolean, default: false

    belongs_to :page, Atlas.Communities.Page
    belongs_to :proposal, Atlas.Communities.Proposal
    belongs_to :author, Atlas.Accounts.User
    belongs_to :parent, Atlas.Communities.Comment

    has_many :replies, Atlas.Communities.Comment,
      foreign_key: :parent_id,
      preload_order: [asc: :inserted_at]

    has_many :votes, Atlas.Communities.CommentVote

    timestamps(type: :utc_datetime)
  end

  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:body, :page_id, :proposal_id, :author_id, :parent_id])
    |> validate_required([:body, :author_id])
    |> validate_length(:body, min: 1, max: 2000)
    |> validate_exactly_one_parent()
    |> foreign_key_constraint(:page_id)
    |> foreign_key_constraint(:proposal_id)
    |> foreign_key_constraint(:author_id)
    |> foreign_key_constraint(:parent_id)
    |> check_constraint(:page_id, name: :comment_must_have_one_parent)
  end

  defp validate_exactly_one_parent(changeset) do
    page_id = get_field(changeset, :page_id)
    proposal_id = get_field(changeset, :proposal_id)

    case {page_id, proposal_id} do
      {nil, nil} ->
        add_error(changeset, :page_id, "comment must belong to a page or proposal")

      {_, nil} ->
        changeset

      {nil, _} ->
        changeset

      {_, _} ->
        add_error(changeset, :page_id, "comment cannot belong to both a page and proposal")
    end
  end
end
