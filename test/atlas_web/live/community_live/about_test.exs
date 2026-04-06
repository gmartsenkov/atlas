defmodule AtlasWeb.CommunityLive.AboutTest do
  use AtlasWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  test "renders community about page without login", %{conn: conn} do
    owner = user_fixture()
    community = community_fixture(owner, %{"description" => "A wonderful community"})

    {:ok, _lv, html} = live(conn, ~p"/c/#{community.name}/about")

    assert html =~ community.name
    assert html =~ "A wonderful community"
    assert html =~ owner.nickname
  end

  test "shows page count", %{conn: conn} do
    owner = user_fixture()
    community = community_fixture(owner)
    page_fixture(community, owner)
    page_fixture(community, owner)

    {:ok, _lv, html} = live(conn, ~p"/c/#{community.name}/about")

    assert html =~ "2 pages"
  end

  test "nonexistent community raises 404", %{conn: conn} do
    assert_raise AtlasWeb.NotFoundError, fn ->
      live(conn, ~p"/c/nonexistent_community_xyz/about")
    end
  end
end
