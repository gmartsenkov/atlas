defmodule Atlas.Communities.ReportsContextTest do
  use Atlas.DataCase, async: true

  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  alias Atlas.Communities.ReportsContext

  setup do
    owner = user_fixture()
    community = community_fixture(owner)
    reporter = user_fixture()
    page = page_fixture(community, owner)
    comment = page_comment_fixture(page, reporter)

    %{
      owner: owner,
      community: community,
      reporter: reporter,
      page: page,
      comment: comment
    }
  end

  describe "create_report/2" do
    test "creates a community report", %{reporter: reporter, community: community} do
      {:ok, report} =
        ReportsContext.create_report(reporter, %{
          reason: "spam",
          community_id: community.id
        })

      assert report.reason == "spam"
      assert report.community_id == community.id
      assert report.reporter_id == reporter.id
      assert report.status == "pending"
      assert is_nil(report.page_id)
      assert is_nil(report.comment_id)
    end

    test "creates a page report", %{reporter: reporter, community: community, page: page} do
      {:ok, report} =
        ReportsContext.create_report(reporter, %{
          reason: "misinformation",
          community_id: community.id,
          page_id: page.id
        })

      assert report.page_id == page.id
      assert report.community_id == community.id
    end

    test "creates a comment report", %{
      reporter: reporter,
      community: community,
      page: page,
      comment: comment
    } do
      {:ok, report} =
        ReportsContext.create_report(reporter, %{
          reason: "harassment",
          community_id: community.id,
          page_id: page.id,
          comment_id: comment.id
        })

      assert report.comment_id == comment.id
      assert report.page_id == page.id
    end

    test "creates a report with optional details", %{reporter: reporter, community: community} do
      {:ok, report} =
        ReportsContext.create_report(reporter, %{
          reason: "other",
          details: "Some details here",
          community_id: community.id
        })

      assert report.details == "Some details here"
    end

    test "validates reason is in allowed list", %{reporter: reporter, community: community} do
      {:error, changeset} =
        ReportsContext.create_report(reporter, %{
          reason: "invalid_reason",
          community_id: community.id
        })

      assert %{reason: ["is invalid"]} = errors_on(changeset)
    end

    test "creates a user report without community_id", %{reporter: reporter} do
      reported_user = user_fixture()

      {:ok, report} =
        ReportsContext.create_report(reporter, %{
          reason: "harassment",
          reported_user_id: reported_user.id
        })

      assert report.reported_user_id == reported_user.id
      assert report.reporter_id == reporter.id
      assert is_nil(report.community_id)
    end

    test "validates details max length", %{reporter: reporter, community: community} do
      {:error, changeset} =
        ReportsContext.create_report(reporter, %{
          reason: "spam",
          details: String.duplicate("a", 2001),
          community_id: community.id
        })

      assert %{details: [msg]} = errors_on(changeset)
      assert msg =~ "at most 2000"
    end
  end

  describe "list_community_reports/3" do
    test "returns page/comment reports for community", %{
      reporter: reporter,
      community: community,
      page: page
    } do
      report = report_fixture(reporter, %{community_id: community.id, page_id: page.id})
      result = ReportsContext.list_community_reports(community, "pending")

      assert length(result.items) == 1
      assert hd(result.items).id == report.id
    end

    test "excludes community-only reports", %{reporter: reporter, community: community} do
      _community_report = report_fixture(reporter, %{community_id: community.id})
      result = ReportsContext.list_community_reports(community, "pending")

      assert result.items == []
    end

    test "excludes user reports", %{reporter: reporter, community: community} do
      reported_user = user_fixture()

      _user_report =
        report_fixture(reporter, %{reported_user_id: reported_user.id})

      result = ReportsContext.list_community_reports(community, "pending")
      assert result.items == []
    end

    test "does not return reports from other communities", %{reporter: reporter, owner: owner} do
      other_owner = user_fixture()
      other_community = community_fixture(other_owner)
      other_page = page_fixture(other_community, other_owner)

      _report =
        report_fixture(reporter, %{community_id: other_community.id, page_id: other_page.id})

      community2 = community_fixture(owner)
      result = ReportsContext.list_community_reports(community2, "pending")

      assert result.items == []
    end

    test "filters by status", %{
      reporter: reporter,
      community: community,
      owner: owner,
      page: page
    } do
      report = report_fixture(reporter, %{community_id: community.id, page_id: page.id})
      ReportsContext.resolve_report(report, owner)

      pending_page = ReportsContext.list_community_reports(community, "pending")
      assert pending_page.items == []

      resolved_page = ReportsContext.list_community_reports(community, "resolved")
      assert length(resolved_page.items) == 1
    end
  end

  describe "count_community_reports_by_status/1" do
    test "returns correct counts for page/comment reports only", %{
      reporter: reporter,
      community: community,
      owner: owner,
      page: page
    } do
      report1 = report_fixture(reporter, %{community_id: community.id, page_id: page.id})

      _report2 =
        report_fixture(reporter, %{
          community_id: community.id,
          page_id: page.id,
          reason: "harassment"
        })

      ReportsContext.resolve_report(report1, owner)

      counts = ReportsContext.count_community_reports_by_status(community)

      assert counts["pending"] == 1
      assert counts["resolved"] == 1
    end

    test "excludes community-only and user reports from counts", %{
      reporter: reporter,
      community: community
    } do
      _community_report = report_fixture(reporter, %{community_id: community.id})
      reported_user = user_fixture()
      _user_report = report_fixture(reporter, %{reported_user_id: reported_user.id})

      counts = ReportsContext.count_community_reports_by_status(community)

      assert counts == %{}
    end
  end

  describe "resolve_report/2" do
    test "sets status to resolved with resolver info", %{
      reporter: reporter,
      community: community,
      owner: owner
    } do
      report = report_fixture(reporter, %{community_id: community.id})
      {:ok, resolved} = ReportsContext.resolve_report(report, owner)

      assert resolved.status == "resolved"
      assert resolved.resolved_by_id == owner.id
      assert resolved.resolved_at
    end
  end

  describe "remove_reported_content/2" do
    test "sets status to removed", %{
      reporter: reporter,
      community: community,
      owner: owner
    } do
      report = report_fixture(reporter, %{community_id: community.id})
      {:ok, removed} = ReportsContext.remove_reported_content(report, owner)

      assert removed.status == "removed"
      assert removed.resolved_by_id == owner.id
      assert removed.resolved_at
    end
  end

  describe "get_report/1" do
    test "returns report with preloads", %{reporter: reporter, community: community} do
      report = report_fixture(reporter, %{community_id: community.id})
      {:ok, fetched} = ReportsContext.get_report(report.id)

      assert fetched.id == report.id
      assert fetched.reporter.id == reporter.id
      assert fetched.community.id == community.id
    end

    test "returns error for nonexistent report" do
      assert {:error, :not_found} = ReportsContext.get_report(0)
    end
  end
end
