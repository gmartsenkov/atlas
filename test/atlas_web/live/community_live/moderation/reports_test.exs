defmodule AtlasWeb.CommunityLive.Moderation.ReportsTest do
  use AtlasWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  alias Atlas.Communities

  setup %{conn: conn} do
    owner = user_fixture()
    community = community_fixture(owner)
    member = user_fixture()
    Communities.join_community(member, community)
    moderator = user_fixture()
    Communities.join_community(moderator, community)
    Communities.set_member_role(community, moderator.id, "moderator")
    reporter = user_fixture()
    Communities.join_community(reporter, community)
    page = page_fixture(community, owner)

    %{
      owner: owner,
      member: member,
      moderator: moderator,
      reporter: reporter,
      community: community,
      page: page,
      conn: conn
    }
  end

  describe "access control" do
    test "regular member cannot access reports", %{conn: conn, member: member, community: community} do
      assert {:error, {:live_redirect, %{flash: flash}}} =
               conn |> log_in_user(member) |> live(~p"/mod/#{community.name}/reports")

      assert flash["error"] =~ "You don't have permission"
    end

    test "unauthenticated user is redirected", %{conn: conn, community: community} do
      assert {:error, {:redirect, _}} = live(conn, ~p"/mod/#{community.name}/reports")
    end
  end

  describe "rendering" do
    test "shows reports heading", %{conn: conn, owner: owner, community: community} do
      {:ok, _lv, html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/reports")

      assert html =~ "Reports"
    end

    test "shows empty state when no reports", %{conn: conn, owner: owner, community: community} do
      {:ok, _lv, html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/reports")

      assert html =~ "No reports found"
    end

    test "shows status filter tabs", %{conn: conn, owner: owner, community: community} do
      {:ok, _lv, html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/reports")

      assert html =~ "Pending"
      assert html =~ "Resolved"
      assert html =~ "Removed"
    end

    test "shows pending page report", %{
      conn: conn,
      owner: owner,
      community: community,
      reporter: reporter,
      page: page
    } do
      report_fixture(reporter, %{
        reason: "spam",
        community_id: community.id,
        page_id: page.id,
        reported_user_id: owner.id
      })

      {:ok, _lv, html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/reports")

      assert html =~ "Page"
      assert html =~ "Spam"
      assert html =~ reporter.nickname
    end

    test "shows pending comment report", %{
      conn: conn,
      owner: owner,
      community: community,
      reporter: reporter,
      page: page
    } do
      {:ok, comment} = Communities.add_comment(page, reporter, %{body: "Bad comment here"})

      report_fixture(reporter, %{
        reason: "harassment",
        community_id: community.id,
        comment_id: comment.id,
        reported_user_id: owner.id
      })

      {:ok, _lv, html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/reports")

      assert html =~ "Comment"
      assert html =~ "Harassment"
      assert html =~ "Bad comment here"
    end

    test "shows report details when present", %{
      conn: conn,
      owner: owner,
      community: community,
      reporter: reporter,
      page: page
    } do
      report_fixture(reporter, %{
        reason: "other",
        details: "This is very problematic content",
        community_id: community.id,
        page_id: page.id,
        reported_user_id: owner.id
      })

      {:ok, _lv, html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/reports")

      assert html =~ "This is very problematic content"
    end

    test "shows pending reports count in sidebar badge", %{
      conn: conn,
      owner: owner,
      community: community,
      reporter: reporter,
      page: page
    } do
      report_fixture(reporter, %{
        reason: "spam",
        community_id: community.id,
        page_id: page.id,
        reported_user_id: owner.id
      })

      report_fixture(reporter, %{
        reason: "harassment",
        community_id: community.id,
        page_id: page.id,
        reported_user_id: owner.id
      })

      {:ok, _lv, html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/reports")

      # Badge with count 2
      assert html =~ ~r/badge-primary[^>]*>\s*2\s*<\/span>/
    end
  end

  describe "resolve action" do
    test "resolving a report removes it from pending list", %{
      conn: conn,
      owner: owner,
      community: community,
      reporter: reporter,
      page: page
    } do
      report =
        report_fixture(reporter, %{
          reason: "spam",
          community_id: community.id,
          page_id: page.id,
          reported_user_id: owner.id
        })

      {:ok, lv, html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/reports")

      assert html =~ "Spam"

      html = render_click(lv, "resolve", %{"id" => to_string(report.id)})
      assert html =~ "Report resolved"
    end
  end

  describe "remove action" do
    test "removing content removes report from pending list", %{
      conn: conn,
      owner: owner,
      community: community,
      reporter: reporter,
      page: page
    } do
      report =
        report_fixture(reporter, %{
          reason: "spam",
          community_id: community.id,
          page_id: page.id,
          reported_user_id: owner.id
        })

      {:ok, lv, _html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/reports")

      html = render_click(lv, "remove", %{"id" => to_string(report.id)})
      assert html =~ "Content removed"
    end
  end

  describe "filtering" do
    test "filters by resolved status", %{
      conn: conn,
      owner: owner,
      community: community,
      reporter: reporter,
      page: page
    } do
      report =
        report_fixture(reporter, %{
          reason: "spam",
          community_id: community.id,
          page_id: page.id,
          reported_user_id: owner.id
        })

      Communities.resolve_report(report, owner)

      {:ok, lv, html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/reports")

      # Default is pending, so resolved report shouldn't show
      assert html =~ "No reports found"

      # Switch to resolved
      html = render_click(lv, "filter-reports", %{"status" => "resolved"})
      assert html =~ "Spam"
    end

    test "filters by removed status", %{
      conn: conn,
      owner: owner,
      community: community,
      reporter: reporter,
      page: page
    } do
      report =
        report_fixture(reporter, %{
          reason: "harassment",
          community_id: community.id,
          page_id: page.id,
          reported_user_id: owner.id
        })

      Communities.remove_reported_content(report, owner)

      {:ok, lv, _html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/reports")

      html = render_click(lv, "filter-reports", %{"status" => "removed"})
      assert html =~ "Harassment"
    end
  end

  describe "moderator access" do
    test "moderator can view reports", %{
      conn: conn,
      moderator: moderator,
      community: community,
      reporter: reporter,
      page: page
    } do
      report_fixture(reporter, %{
        reason: "spam",
        community_id: community.id,
        page_id: page.id,
        reported_user_id: moderator.id
      })

      {:ok, _lv, html} =
        conn |> log_in_user(moderator) |> live(~p"/mod/#{community.name}/reports")

      assert html =~ "Reports"
      assert html =~ "Spam"
    end

    test "moderator can resolve reports", %{
      conn: conn,
      moderator: moderator,
      community: community,
      reporter: reporter,
      page: page
    } do
      report =
        report_fixture(reporter, %{
          reason: "spam",
          community_id: community.id,
          page_id: page.id,
          reported_user_id: moderator.id
        })

      {:ok, lv, _html} =
        conn |> log_in_user(moderator) |> live(~p"/mod/#{community.name}/reports")

      html = render_click(lv, "resolve", %{"id" => to_string(report.id)})
      assert html =~ "Report resolved"
    end
  end
end
