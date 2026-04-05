defmodule Atlas.Communities.PageCommentsContext do
  @moduledoc false
  import Ecto.Query

  alias Atlas.Communities.PageComment
  alias Atlas.Repo

  def list_page_comments(page) do
    from(c in PageComment,
      where: c.page_id == ^page.id and is_nil(c.parent_id),
      order_by: [asc: c.inserted_at],
      limit: 200,
      preload: [
        :author,
        replies: ^from(r in PageComment, order_by: r.inserted_at, limit: 50, preload: :author)
      ]
    )
    |> Repo.all()
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
end
