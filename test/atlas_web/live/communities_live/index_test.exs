defmodule AtlasWeb.CommunitiesLive.IndexTest do
  use AtlasWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  test "lists communities without login", %{conn: conn} do
    owner = user_fixture()
    community = community_fixture(owner, %{"name" => "BrowseTestCommunity"})

    {:ok, _lv, html} = live(conn, ~p"/communities")

    assert html =~ "Communities"
    assert html =~ community.name
  end

  test "search filters communities", %{conn: conn} do
    owner = user_fixture()
    community_fixture(owner, %{"name" => "AlphaCommunity"})
    community_fixture(owner, %{"name" => "BetaCommunity"})

    {:ok, lv, _html} = live(conn, ~p"/communities")

    html = render_change(lv, "search", %{"query" => "Alpha"})
    assert html =~ "AlphaCommunity"
    refute html =~ "BetaCommunity"
  end

  test "accessible with login too", %{conn: conn} do
    user = user_fixture()

    {:ok, _lv, html} =
      conn |> log_in_user(user) |> live(~p"/communities")

    assert html =~ "Communities"
  end
end
