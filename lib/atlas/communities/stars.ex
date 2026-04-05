defmodule Atlas.Communities.Stars do
  @moduledoc false
  import Ecto.Query

  alias Atlas.Communities.PageStar
  alias Atlas.Repo

  def star_page(user, page) do
    %PageStar{}
    |> PageStar.changeset(%{user_id: user.id, page_id: page.id})
    |> Repo.insert()
  end

  def unstar_page(user, page) do
    Repo.delete_all(
      from s in PageStar,
        where: s.user_id == ^user.id and s.page_id == ^page.id
    )

    :ok
  end

  def page_starred?(user, page) do
    Repo.exists?(
      from s in PageStar,
        where: s.user_id == ^user.id and s.page_id == ^page.id
    )
  end

  def count_page_stars(page) do
    Repo.aggregate(
      from(s in PageStar, where: s.page_id == ^page.id),
      :count
    )
  end
end
