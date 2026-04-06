defmodule Atlas.Communities.PageCommentsContext do
  @moduledoc false
  import Ecto.Query

  alias Atlas.Communities.PageComment
  alias Atlas.Pagination
  alias Atlas.Repo

  def count_page_comments(page) do
    from(c in PageComment, where: c.page_id == ^page.id)
    |> Repo.aggregate(:count)
  end

  def list_page_comments(page, opts \\ []) do
    from(c in PageComment,
      where: c.page_id == ^page.id and is_nil(c.parent_id),
      order_by: [asc: c.inserted_at],
      preload: [
        :author,
        replies: ^from(r in PageComment, order_by: r.inserted_at, limit: 50, preload: :author)
      ]
    )
    |> Pagination.paginate(opts)
  end

  def add_page_comment(page, author, attrs) do
    %PageComment{}
    |> PageComment.changeset(
      attrs
      |> Map.put(:page_id, page.id)
      |> Map.put(:author_id, author.id)
    )
    |> Repo.insert()
  end

  def reply_to_page_comment(page, parent, author, attrs) do
    if parent.parent_id != nil do
      {:error, :no_nested_replies}
    else
      %PageComment{}
      |> PageComment.changeset(
        attrs
        |> Map.put(:page_id, page.id)
        |> Map.put(:author_id, author.id)
        |> Map.put(:parent_id, parent.id)
      )
      |> Repo.insert()
    end
  end

  def delete_page_comment(comment) do
    Repo.delete(comment)
  end

  def get_page_comment(id) do
    case Repo.get(PageComment, id) do
      nil -> {:error, :not_found}
      comment -> {:ok, Repo.preload(comment, :author)}
    end
  end

  def get_page_comment_with_replies(id) do
    case Repo.get(PageComment, id) do
      nil ->
        {:error, :not_found}

      comment ->
        {:ok,
         Repo.preload(comment, [
           :author,
           replies: from(r in PageComment, order_by: r.inserted_at, limit: 50, preload: :author)
         ])}
    end
  end
end
