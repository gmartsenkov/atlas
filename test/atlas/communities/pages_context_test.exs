defmodule Atlas.Communities.PagesContextTest do
  use Atlas.DataCase, async: true

  alias Atlas.Communities.PagesContext

  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  setup do
    owner = user_fixture()
    community = community_fixture(owner)
    %{owner: owner, community: community}
  end

  describe "get_page_by_slugs/2" do
    test "returns page with preloads", %{community: community, owner: owner} do
      page = page_fixture(community, owner, %{"title" => "Test", "slug" => "test-page"})
      assert {:ok, found} = PagesContext.get_page_by_slugs(community.name, "test-page")
      assert found.id == page.id
      assert found.community.id == community.id
      assert found.owner.id == owner.id
      assert is_list(found.sections)
    end

    test "returns error for nonexistent slug", %{community: community} do
      assert {:error, :not_found} = PagesContext.get_page_by_slugs(community.name, "nope")
    end

    test "returns error for nonexistent community" do
      assert {:error, :not_found} = PagesContext.get_page_by_slugs("nonexistent", "any")
    end
  end

  describe "create_page/2" do
    test "creates page with a default section", %{community: community, owner: owner} do
      attrs = %{"title" => "New Page", "slug" => "new-page", "community_id" => community.id}
      assert {:ok, page} = PagesContext.create_page(attrs, owner)
      assert page.title == "New Page"

      sections = Atlas.Communities.Sections.list_sections(page.id)
      assert length(sections) == 1
      assert hd(sections).sort_order == 0
    end

    test "validates required fields", %{owner: owner} do
      assert {:error, changeset} = PagesContext.create_page(%{}, owner)
      assert %{title: ["can't be blank"]} = errors_on(changeset)
    end

    test "enforces unique slug per community", %{community: community, owner: owner} do
      attrs = %{"title" => "Page", "slug" => "same-slug", "community_id" => community.id}
      {:ok, _} = PagesContext.create_page(attrs, owner)

      assert {:error, changeset} = PagesContext.create_page(attrs, owner)
      assert %{slug: ["already exists in this community"]} = errors_on(changeset)
    end
  end

  describe "update_page/2" do
    test "updates page fields", %{community: community, owner: owner} do
      page = page_fixture(community, owner)
      assert {:ok, updated} = PagesContext.update_page(page, %{"title" => "Updated Title"})
      assert updated.title == "Updated Title"
    end
  end

  describe "change_page/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = PagesContext.change_page()
    end

    test "returns changeset with attrs", %{community: community, owner: owner} do
      page = page_fixture(community, owner)
      assert %Ecto.Changeset{} = PagesContext.change_page(page, %{title: "New"})
    end
  end

  describe "reorder_pages/2" do
    test "reorders pages", %{community: community, owner: owner} do
      p1 = page_fixture(community, owner, %{"title" => "First", "slug" => "first"})
      p2 = page_fixture(community, owner, %{"title" => "Second", "slug" => "second"})

      assert :ok = PagesContext.reorder_pages(community, [p2.id, p1.id])

      {:ok, reloaded} = Atlas.Communities.CommunityManager.get_community_by_name(community.name)
      page_ids = Enum.map(reloaded.pages, & &1.id)
      assert hd(page_ids) == p2.id
    end
  end
end
