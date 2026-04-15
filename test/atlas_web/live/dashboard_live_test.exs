defmodule AtlasWeb.DashboardLiveTest do
  use AtlasWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  alias Atlas.Communities.CommunityManager
  alias Atlas.Communities.Sections

  setup %{conn: conn} do
    owner = user_fixture()
    community = community_fixture(owner, %{"suggestions_enabled" => true})
    member = user_fixture()
    CommunityManager.join_community(member, community)

    page = page_fixture(community, owner)
    [section | _] = Sections.list_sections(page.id)
    proposal = proposal_fixture(section, member)

    %{
      owner: owner,
      member: member,
      community: community,
      page: page,
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

    test "authenticated user can access my proposals", %{conn: conn, member: member} do
      {:ok, _lv, html} = conn |> log_in_user(member) |> live(~p"/dashboard")

      assert html =~ "My Proposals"
    end
  end

  describe "proposals display" do
    test "user sees their own proposals", %{conn: conn, member: member, page: page} do
      {:ok, _lv, html} = conn |> log_in_user(member) |> live(~p"/dashboard")

      assert html =~ "My Proposals"
      assert html =~ page.title
    end

    test "user does not see other users' proposals", %{conn: conn, community: community} do
      other = user_fixture()
      CommunityManager.join_community(other, community)

      {:ok, _lv, html} = conn |> log_in_user(other) |> live(~p"/dashboard")

      assert html =~ "No proposals found."
    end
  end

  describe "filtering" do
    test "can filter proposals by status", %{conn: conn, member: member} do
      {:ok, lv, _html} = conn |> log_in_user(member) |> live(~p"/dashboard")

      html = render_click(lv, "filter-proposals", %{"status" => "pending"})
      assert html =~ "Pending"
    end

    test "approved filter shows no proposals when none approved", %{conn: conn, member: member} do
      {:ok, lv, _html} = conn |> log_in_user(member) |> live(~p"/dashboard")

      html = render_click(lv, "filter-proposals", %{"status" => "approved"})
      assert html =~ "No proposals found."
    end
  end
end
