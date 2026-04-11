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

  describe "reports" do
    test "owner sees reports section with pending page reports", %{
      conn: conn,
      owner: owner,
      community: community,
      page: page
    } do
      reporter = user_fixture()
      report_fixture(reporter, %{community_id: community.id, page_id: page.id, reason: "spam"})

      {:ok, _lv, html} = conn |> log_in_user(owner) |> live(~p"/dashboard")

      assert html =~ "Reports"
      assert html =~ "Spam"
    end

    test "community-only reports do not appear in dashboard", %{
      conn: conn,
      owner: owner,
      community: community
    } do
      reporter = user_fixture()
      report_fixture(reporter, %{community_id: community.id, reason: "harassment"})

      {:ok, _lv, html} = conn |> log_in_user(owner) |> live(~p"/dashboard")

      refute html =~ "Harassment"
    end

    test "user reports do not appear in dashboard", %{
      conn: conn,
      owner: owner
    } do
      reporter = user_fixture()
      reported_user = user_fixture()
      report_fixture(reporter, %{reported_user_id: reported_user.id, reason: "harassment"})

      {:ok, _lv, html} = conn |> log_in_user(owner) |> live(~p"/dashboard")

      refute html =~ "Harassment"
    end

    test "reports from other communities are not shown", %{
      conn: conn,
      owner: owner,
      community: _community
    } do
      other_owner = user_fixture()
      other_community = community_fixture(other_owner)
      other_page = page_fixture(other_community, other_owner)
      reporter = user_fixture()

      report_fixture(reporter, %{
        community_id: other_community.id,
        page_id: other_page.id,
        reason: "harassment"
      })

      {:ok, _lv, html} = conn |> log_in_user(owner) |> live(~p"/dashboard")

      refute html =~ "Harassment"
    end

    test "can filter reports by status", %{
      conn: conn,
      owner: owner,
      community: community,
      page: page
    } do
      reporter = user_fixture()
      report = report_fixture(reporter, %{community_id: community.id, page_id: page.id})
      Communities.resolve_report(report, owner)

      {:ok, lv, _html} = conn |> log_in_user(owner) |> live(~p"/dashboard")

      html = render_click(lv, "filter-reports", %{"status" => "resolved"})
      assert html =~ "Spam"
    end

    test "can dismiss a report", %{
      conn: conn,
      owner: owner,
      community: community,
      page: page
    } do
      reporter = user_fixture()
      report = report_fixture(reporter, %{community_id: community.id, page_id: page.id})

      {:ok, lv, _html} = conn |> log_in_user(owner) |> live(~p"/dashboard")

      render_click(lv, "resolve-report", %{"id" => to_string(report.id)})

      {:ok, resolved} = Communities.get_report(report.id)
      assert resolved.status == "resolved"
    end

    test "can remove reported content", %{
      conn: conn,
      owner: owner,
      community: community,
      page: page
    } do
      reporter = user_fixture()
      report = report_fixture(reporter, %{community_id: community.id, page_id: page.id})

      {:ok, lv, _html} = conn |> log_in_user(owner) |> live(~p"/dashboard")

      render_click(lv, "remove-reported-content", %{"id" => to_string(report.id)})

      {:ok, removed} = Communities.get_report(report.id)
      assert removed.status == "removed"
    end

    test "regular member does not see reports section", %{conn: conn, member: member} do
      {:ok, _lv, html} = conn |> log_in_user(member) |> live(~p"/dashboard")

      refute html =~ "Reports"
    end
  end
end
