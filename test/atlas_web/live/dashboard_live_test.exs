defmodule AtlasWeb.DashboardLiveTest do
  use AtlasWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  alias Atlas.Communities

  setup %{conn: conn} do
    owner = user_fixture()
    community = community_fixture(owner, %{"suggestions_enabled" => true})
    member = user_fixture()
    Communities.join_community(member, community)

    page = page_fixture(community, owner)
    [section | _] = Communities.list_sections(page.id)
    proposal = proposal_fixture(section, member)

    %{
      owner: owner,
      member: member,
      community: community,
      proposal: proposal,
      conn: conn
    }
  end

  describe "access control" do
    test "anonymous user is redirected to login", %{conn: conn} do
      assert {:error, {:redirect, %{to: path, flash: flash}}} = live(conn, ~p"/dashboard")

      assert path == ~p"/users/log-in"
      assert flash["error"] == "You must log in to access this page."
    end

    test "authenticated user can access dashboard", %{conn: conn, owner: owner} do
      {:ok, _lv, html} = conn |> log_in_user(owner) |> live(~p"/dashboard")

      assert html =~ "Dashboard"
    end
  end

  describe "community proposals" do
    test "owner sees community proposals", %{
      conn: conn,
      owner: owner,
      community: community
    } do
      {:ok, _lv, html} = conn |> log_in_user(owner) |> live(~p"/dashboard")

      assert html =~ "Community Proposals"
      assert html =~ community.name
    end

    test "regular member sees only their own proposals", %{conn: conn, member: member} do
      {:ok, _lv, html} = conn |> log_in_user(member) |> live(~p"/dashboard")

      refute html =~ "Community Proposals"
      assert html =~ "My Proposals"
    end
  end

  describe "filtering" do
    test "can filter community proposals by status", %{conn: conn, owner: owner} do
      {:ok, lv, _html} = conn |> log_in_user(owner) |> live(~p"/dashboard")

      html = render_click(lv, "filter-community-proposals", %{"status" => "approved"})
      assert html =~ "Approved"
    end

    test "can filter user proposals by status", %{conn: conn, member: member} do
      {:ok, lv, _html} = conn |> log_in_user(member) |> live(~p"/dashboard")

      html = render_click(lv, "filter-user-proposals", %{"status" => "pending"})
      assert html =~ "Pending"
    end
  end
end
