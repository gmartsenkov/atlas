defmodule Atlas.Communities.PagesContext do
  @moduledoc false
  import Ecto.Query

  alias Atlas.Communities.{Community, Helpers, Page, Section}
  alias Atlas.Repo

  def get_page_by_slugs(community_name, page_slug) do
    query =
      from(p in Page,
        join: c in Community,
        on: c.id == p.community_id,
        where: c.name == ^community_name and p.slug == ^page_slug,
        preload: [:community, :owner, sections: ^from(s in Section, order_by: s.sort_order)]
      )

    case Repo.one(query) do
      nil -> {:error, :not_found}
      page -> {:ok, page}
    end
  end

  def create_page(attrs, owner) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:page, fn _changes ->
      %Page{}
      |> Page.changeset(Map.put(attrs, "owner_id", owner.id))
    end)
    |> Ecto.Multi.insert(:section, fn %{page: page} ->
      %Section{}
      |> Section.changeset(%{
        content: [],
        sort_order: 0,
        page_id: page.id
      })
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{page: page}} -> {:ok, page}
      {:error, :page, changeset, _} -> {:error, changeset}
      {:error, :section, changeset, _} -> {:error, changeset}
    end
  end

  def update_page(page, attrs) do
    page
    |> Page.changeset(attrs)
    |> Repo.update()
  end

  def change_page(page \\ %Page{}, attrs \\ %{}) do
    Page.changeset(page, attrs)
  end

  def reorder_pages(community, ids) when is_list(ids) do
    Helpers.batch_reorder(Page, community.id, ids)
  end
end
