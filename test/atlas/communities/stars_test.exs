defmodule Atlas.Communities.StarsTest do
  use Atlas.DataCase, async: true

  alias Atlas.Communities.Stars

  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  setup do
    owner = user_fixture()
    community = community_fixture(owner)
    page = page_fixture(community, owner)
    %{owner: owner, community: community, page: page}
  end

  describe "star_page/2" do
    test "creates a star", %{owner: user, page: page} do
      assert {:ok, star} = Stars.star_page(user, page)
      assert star.user_id == user.id
      assert star.page_id == page.id
    end

    test "returns error for duplicate star", %{owner: user, page: page} do
      {:ok, _} = Stars.star_page(user, page)
      assert {:error, _changeset} = Stars.star_page(user, page)
    end
  end

  describe "unstar_page/2" do
    test "removes an existing star", %{owner: user, page: page} do
      {:ok, _} = Stars.star_page(user, page)
      assert :ok = Stars.unstar_page(user, page)
      refute Stars.page_starred?(user, page)
    end

    test "returns :ok even if no star exists", %{owner: user, page: page} do
      assert :ok = Stars.unstar_page(user, page)
    end
  end

  describe "page_starred?/2" do
    test "returns false when not starred", %{owner: user, page: page} do
      refute Stars.page_starred?(user, page)
    end

    test "returns true when starred", %{owner: user, page: page} do
      {:ok, _} = Stars.star_page(user, page)
      assert Stars.page_starred?(user, page)
    end
  end

  describe "count_page_stars/1" do
    test "returns 0 with no stars", %{page: page} do
      assert 0 == Stars.count_page_stars(page)
    end

    test "returns correct count", %{page: page, owner: owner} do
      {:ok, _} = Stars.star_page(owner, page)

      other_user = user_fixture()
      {:ok, _} = Stars.star_page(other_user, page)

      assert 2 == Stars.count_page_stars(page)
    end
  end
end
