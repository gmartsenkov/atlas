defmodule AtlasWeb.HomeLiveTest do
  use AtlasWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  test "renders landing page", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/")

    assert html =~ "Shared knowledge"
    assert html =~ "Create a Community"
    assert html =~ "Browse Communities"
  end

  test "shows communities on home page", %{conn: conn} do
    owner = user_fixture()
    community = community_fixture(owner, %{"name" => "HomeTestCommunity"})

    {:ok, _lv, html} = live(conn, ~p"/")

    assert html =~ community.name
  end
end
