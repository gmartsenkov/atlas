defmodule Atlas.Communities do
  import Ecto.Query
  alias Atlas.Repo
  alias Atlas.Communities.{Community, Page}

  def list_communities do
    Community
    |> order_by(:name)
    |> Repo.all()
    |> Repo.preload(:pages)
  end

  def search_communities(query) when is_binary(query) and query != "" do
    wildcard = "%#{query}%"

    Community
    |> where([c], ilike(c.name, ^wildcard) or ilike(c.description, ^wildcard))
    |> order_by(:name)
    |> Repo.all()
    |> Repo.preload(:pages)
  end

  def search_communities(_), do: list_communities()

  def get_community_by_slug!(slug) do
    Community
    |> Repo.get_by!(slug: slug)
    |> Repo.preload(pages: from(p in Page, order_by: p.title))
  end

  def create_community(attrs) do
    %Community{}
    |> Community.changeset(attrs)
    |> Repo.insert()
  end

  def change_community(community \\ %Community{}, attrs \\ %{}) do
    Community.changeset(community, attrs)
  end

  def get_page_by_slugs!(community_slug, page_slug) do
    from(p in Page,
      join: c in Community,
      on: c.id == p.community_id,
      where: c.slug == ^community_slug and p.slug == ^page_slug,
      preload: :community
    )
    |> Repo.one!()
  end

  def create_page(attrs) do
    %Page{}
    |> Page.changeset(attrs)
    |> Repo.insert()
  end

  def update_page(page, attrs) do
    page
    |> Page.changeset(attrs)
    |> Repo.update()
  end

  def change_page(page \\ %Page{}, attrs \\ %{}) do
    Page.changeset(page, attrs)
  end

end
