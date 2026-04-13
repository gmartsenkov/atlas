defmodule AtlasWeb.CommunityLive.Moderation.ProposalsTest do
  use AtlasWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  alias Atlas.Communities
  alias Atlas.Communities.Sections

  setup %{conn: conn} do
    owner = user_fixture()
    community = community_fixture(owner)
    member = user_fixture()
    Communities.join_community(member, community)
    moderator = user_fixture()
    Communities.join_community(moderator, community)
    Communities.set_member_role(community, moderator.id, "moderator")
    author = user_fixture()
    Communities.join_community(author, community)
    page = page_fixture(community, owner)
    [section | _] = Sections.list_sections(page.id)

    %{
      owner: owner,
      member: member,
      moderator: moderator,
      author: author,
      community: community,
      page: page,
      section: section,
      conn: conn
    }
  end

  describe "rendering" do
    test "shows proposals heading", %{conn: conn, owner: owner, community: community} do
      {:ok, _lv, html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/proposals")

      assert html =~ "Proposals"
    end

    test "shows empty state when no proposals", %{
      conn: conn,
      owner: owner,
      community: community
    } do
      {:ok, _lv, html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/proposals")

      assert html =~ "No proposals found"
    end

    test "shows status filter tabs", %{conn: conn, owner: owner, community: community} do
      {:ok, _lv, html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/proposals")

      assert html =~ "Pending"
      assert html =~ "Approved"
      assert html =~ "Rejected"
    end

    test "shows pending proposals", %{
      conn: conn,
      owner: owner,
      community: community,
      section: section,
      author: author
    } do
      proposal_fixture(section, author)

      {:ok, _lv, html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/proposals")

      assert html =~ "Content edit"
    end

    test "shows page proposals", %{
      conn: conn,
      owner: owner,
      community: community,
      author: author
    } do
      page_proposal_fixture(community, author, %{proposed_title: "My Cool Page"})

      {:ok, _lv, html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/proposals")

      assert html =~ "My Cool Page"
    end

    test "shows pending count in sidebar badge", %{
      conn: conn,
      owner: owner,
      community: community,
      section: section,
      author: author
    } do
      proposal_fixture(section, author)
      proposal_fixture(section, author)

      {:ok, _lv, html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/proposals")

      # Badge with count inside the primary badge span
      assert html =~ ~r/badge-primary[^>]*>\s*2\s*<\/span>/
    end
  end

  describe "filtering" do
    test "filters by approved status", %{
      conn: conn,
      owner: owner,
      community: community,
      section: section,
      author: author
    } do
      proposal = proposal_fixture(section, author)
      Communities.approve_proposal(proposal, owner)

      {:ok, lv, html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/proposals")

      # Default is pending, so approved proposal shouldn't show
      assert html =~ "No proposals found"

      # Switch to approved
      html = render_click(lv, "filter-proposals", %{"status" => "approved"})
      assert html =~ "Content edit"
    end

    test "filters by rejected status", %{
      conn: conn,
      owner: owner,
      community: community,
      section: section,
      author: author
    } do
      proposal = proposal_fixture(section, author)
      Communities.reject_proposal(proposal, owner)

      {:ok, lv, _html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/proposals")

      html = render_click(lv, "filter-proposals", %{"status" => "rejected"})
      assert html =~ "Content edit"
    end

    test "shows correct counts per status", %{
      conn: conn,
      owner: owner,
      community: community,
      section: section,
      author: author
    } do
      p1 = proposal_fixture(section, author)
      _p2 = proposal_fixture(section, author)
      Communities.approve_proposal(p1, owner)

      {:ok, _lv, html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/proposals")

      # One pending, one approved
      assert html =~ "Pending"
      assert html =~ "(1)"
      assert html =~ "Approved"
    end
  end

  describe "moderator access" do
    test "moderator can view proposals", %{
      conn: conn,
      moderator: moderator,
      community: community,
      section: section,
      author: author
    } do
      proposal_fixture(section, author)

      {:ok, _lv, html} =
        conn |> log_in_user(moderator) |> live(~p"/mod/#{community.name}/proposals")

      assert html =~ "Proposals"
      assert html =~ "Content edit"
    end

    test "moderator can filter proposals", %{
      conn: conn,
      moderator: moderator,
      community: community,
      section: section,
      author: author,
      owner: owner
    } do
      proposal = proposal_fixture(section, author)
      Communities.approve_proposal(proposal, owner)

      {:ok, lv, _html} =
        conn |> log_in_user(moderator) |> live(~p"/mod/#{community.name}/proposals")

      html = render_click(lv, "filter-proposals", %{"status" => "approved"})
      assert html =~ "Content edit"
    end
  end
end
