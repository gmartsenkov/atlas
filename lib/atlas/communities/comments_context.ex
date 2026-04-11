defmodule Atlas.Communities.CommentsContext do
  @moduledoc false
  import Ecto.Query

  alias Atlas.Communities.{Comment, Page, Proposal}
  alias Atlas.Pagination
  alias Atlas.Repo

  def count_comments(commentable) do
    field = commentable_field(commentable)

    from(c in Comment, where: field(c, ^field) == ^commentable.id)
    |> Repo.aggregate(:count)
  end

  def list_comments(commentable, opts \\ []) do
    field = commentable_field(commentable)

    from(c in Comment,
      where: field(c, ^field) == ^commentable.id and is_nil(c.parent_id),
      order_by: [asc: c.inserted_at],
      preload: [
        :author,
        replies: ^from(r in Comment, order_by: r.inserted_at, limit: 50, preload: :author)
      ]
    )
    |> Pagination.paginate(opts)
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
    Repo.delete(comment)
  end

  def redact_comment(comment) do
    comment
    |> Ecto.Changeset.change(deleted: true)
    |> Repo.update()
  end

  def get_comment(id) do
    case Repo.get(Comment, id) do
      nil -> {:error, :not_found}
      comment -> {:ok, Repo.preload(comment, :author)}
    end
  end

  def get_comment_with_replies(id) do
    case Repo.get(Comment, id) do
      nil ->
        {:error, :not_found}

      comment ->
        {:ok,
         Repo.preload(comment, [
           :author,
           replies: from(r in Comment, order_by: r.inserted_at, limit: 50, preload: :author)
         ])}
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
