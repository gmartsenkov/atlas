defmodule Atlas.Communities.CommentsContext do
  @moduledoc false
  import Ecto.Query

  alias Atlas.Communities.{Comment, CommentVote, Page, Proposal}
  alias Atlas.Pagination
  alias Atlas.Repo

  @default_reply_limit 5

  def default_reply_limit, do: @default_reply_limit

  def count_comments(commentable) do
    field = commentable_field(commentable)

    from(c in Comment, where: field(c, ^field) == ^commentable.id)
    |> Repo.aggregate(:count)
  end

  def list_comments(commentable, opts \\ []) do
    field = commentable_field(commentable)
    sort = Keyword.get(opts, :sort, "best")

    replies_query =
      from(r in Comment,
        order_by: r.inserted_at,
        limit: ^@default_reply_limit,
        preload: :author
      )

    base =
      from(c in Comment,
        where: field(c, ^field) == ^commentable.id and is_nil(c.parent_id),
        preload: [:author, replies: ^replies_query]
      )

    base
    |> apply_sort(sort)
    |> Pagination.paginate(opts)
  end

  defp apply_sort(query, "old") do
    from(c in query, order_by: [asc: c.inserted_at, asc: c.id])
  end

  defp apply_sort(query, "new") do
    from(c in query, order_by: [desc: c.inserted_at, desc: c.id])
  end

  defp apply_sort(query, "best") do
    scores =
      from(v in CommentVote,
        group_by: v.comment_id,
        select: %{comment_id: v.comment_id, score: sum(v.value)}
      )

    from(c in query,
      left_join: s in subquery(scores),
      on: s.comment_id == c.id,
      order_by: [desc: coalesce(s.score, 0), desc: c.inserted_at, desc: c.id]
    )
  end

  def add_comment(commentable, author, attrs) do
    field = commentable_field(commentable)

    %Comment{}
    |> Comment.changeset(
      attrs
      |> Map.put(field, commentable.id)
      |> Map.put(:author_id, author.id)
    )
    |> Repo.insert()
  end

  def reply_to_comment(_commentable, parent, author, attrs) do
    if parent.parent_id != nil do
      {:error, :no_nested_replies}
    else
      field = commentable_field_from_comment(parent)

      %Comment{}
      |> Comment.changeset(
        attrs
        |> Map.put(field, field_value(parent, field))
        |> Map.put(:author_id, author.id)
        |> Map.put(:parent_id, parent.id)
      )
      |> Repo.insert()
    end
  end

  def delete_comment(comment) do
    comment
    |> Ecto.Changeset.change(deleted: true)
    |> Repo.update()
  end

  def count_replies(parent_id) do
    from(c in Comment, where: c.parent_id == ^parent_id)
    |> Repo.aggregate(:count)
  end

  def list_replies(parent_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    offset = Keyword.get(opts, :offset, 0)

    from(c in Comment,
      where: c.parent_id == ^parent_id,
      order_by: [asc: c.inserted_at],
      limit: ^limit,
      offset: ^offset,
      preload: :author
    )
    |> Repo.all()
  end

  def get_comment(id) do
    case Repo.get(Comment, id) do
      nil -> {:error, :not_found}
      comment -> {:ok, Repo.preload(comment, :author)}
    end
  end

  def get_comment_with_replies(id, opts \\ []) do
    limit = Keyword.get(opts, :reply_limit, @default_reply_limit)

    case Repo.get(Comment, id) do
      nil ->
        {:error, :not_found}

      comment ->
        {:ok,
         Repo.preload(comment, [
           :author,
           replies: from(r in Comment, order_by: r.inserted_at, limit: ^limit, preload: :author)
         ])}
    end
  end

  def vote_comment(user, comment_id, value) when value in [1, -1] do
    %CommentVote{}
    |> CommentVote.changeset(%{user_id: user.id, comment_id: comment_id, value: value})
    |> Repo.insert(
      on_conflict: [set: [value: value, updated_at: DateTime.utc_now()]],
      conflict_target: [:user_id, :comment_id],
      returning: true
    )
  end

  def unvote_comment(user, comment_id) do
    Repo.delete_all(
      from(v in CommentVote,
        where: v.user_id == ^user.id and v.comment_id == ^comment_id
      )
    )

    :ok
  end

  def comment_scores(comment_ids) when is_list(comment_ids) do
    if comment_ids == [] do
      %{}
    else
      from(v in CommentVote,
        where: v.comment_id in ^comment_ids,
        group_by: v.comment_id,
        select: {v.comment_id, sum(v.value)}
      )
      |> Repo.all()
      |> Map.new()
    end
  end

  def user_votes(nil, _comment_ids), do: %{}

  def user_votes(user, comment_ids) when is_list(comment_ids) do
    if comment_ids == [] do
      %{}
    else
      from(v in CommentVote,
        where: v.user_id == ^user.id and v.comment_id in ^comment_ids,
        select: {v.comment_id, v.value}
      )
      |> Repo.all()
      |> Map.new()
    end
  end

  defp commentable_field(%Page{}), do: :page_id
  defp commentable_field(%Proposal{}), do: :proposal_id

  defp commentable_field_from_comment(%Comment{page_id: page_id}) when not is_nil(page_id),
    do: :page_id

  defp commentable_field_from_comment(%Comment{proposal_id: proposal_id})
       when not is_nil(proposal_id),
       do: :proposal_id

  defp field_value(%Comment{page_id: page_id}, :page_id), do: page_id
  defp field_value(%Comment{proposal_id: proposal_id}, :proposal_id), do: proposal_id
end
