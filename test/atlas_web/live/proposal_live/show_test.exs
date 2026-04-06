defmodule AtlasWeb.ProposalLive.ShowTest do
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
    moderator = user_fixture()
    Communities.join_community(moderator, community)
    Communities.set_member_role(community, moderator.id, "moderator")
    other_member = user_fixture()
    Communities.join_community(other_member, community)

    page = page_fixture(community, owner)
    [section | _] = Communities.list_sections(page.id)
    proposal = proposal_fixture(section, member)
    page_proposal = page_proposal_fixture(community, member)

    %{
      owner: owner,
      member: member,
      moderator: moderator,
      other_member: other_member,
      community: community,
      page: page,
      section: section,
      proposal: proposal,
      page_proposal: page_proposal,
      conn: conn
    }
  end

  describe "section proposal viewing" do
    test "any authenticated user can view section proposal", %{
      conn: conn,
      member: member,
      other_member: other_member,
      community: community,
      page: page,
      proposal: proposal
    } do
      {:ok, _lv, html} =
        conn
        |> log_in_user(other_member)
        |> live(~p"/c/#{community.name}/#{page.slug}/proposals/#{proposal.id}")

      assert html =~ "Proposal Review"
      assert html =~ member.nickname
    end

    test "anonymous user is redirected to login", %{
      conn: conn,
      community: community,
      page: page,
      proposal: proposal
    } do
      assert {:error, {:redirect, %{to: path}}} =
               live(conn, ~p"/c/#{community.name}/#{page.slug}/proposals/#{proposal.id}")

      assert path == ~p"/users/log-in"
    end
  end

  describe "page proposal viewing" do
    test "any authenticated user can view page proposal", %{
      conn: conn,
      other_member: other_member,
      community: community,
      page_proposal: page_proposal
    } do
      {:ok, _lv, html} =
        conn
        |> log_in_user(other_member)
        |> live(~p"/c/#{community.name}/page-proposals/#{page_proposal.id}")

      assert html =~ "Proposal Review"
    end
  end

  describe "approve/reject authorization" do
    test "page owner can approve section proposal", %{
      conn: conn,
      owner: owner,
      community: community,
      page: page,
      proposal: proposal
    } do
      {:ok, lv, html} =
        conn
        |> log_in_user(owner)
        |> live(~p"/c/#{community.name}/#{page.slug}/proposals/#{proposal.id}")

      # Owner should see approve/reject buttons
      assert html =~ "Approve"
      assert html =~ "Reject"

      render_click(lv, "approve")
      assert_redirect(lv, ~p"/dashboard")

      {:ok, updated} = Communities.get_proposal(proposal.id)
      assert updated.status == "approved"
    end

    test "moderator can approve section proposal", %{
      conn: conn,
      moderator: moderator,
      community: community,
      page: page,
      proposal: proposal
    } do
      {:ok, lv, _html} =
        conn
        |> log_in_user(moderator)
        |> live(~p"/c/#{community.name}/#{page.slug}/proposals/#{proposal.id}")

      render_click(lv, "approve")
      assert_redirect(lv, ~p"/dashboard")

      {:ok, updated} = Communities.get_proposal(proposal.id)
      assert updated.status == "approved"
    end

    test "regular member cannot approve proposal", %{
      conn: conn,
      other_member: other_member,
      community: community,
      page: page,
      proposal: proposal
    } do
      {:ok, lv, html} =
        conn
        |> log_in_user(other_member)
        |> live(~p"/c/#{community.name}/#{page.slug}/proposals/#{proposal.id}")

      # Non-owner should not see approve/reject buttons
      refute html =~ "Approve"
      refute html =~ "Reject"

      # Even if they send the event directly, it should be denied
      render_click(lv, "approve")

      {:ok, updated} = Communities.get_proposal(proposal.id)
      assert updated.status == "pending"
    end

    test "regular member cannot reject proposal", %{
      conn: conn,
      other_member: other_member,
      community: community,
      page: page,
      proposal: proposal
    } do
      {:ok, lv, _html} =
        conn
        |> log_in_user(other_member)
        |> live(~p"/c/#{community.name}/#{page.slug}/proposals/#{proposal.id}")

      render_click(lv, "reject")

      {:ok, updated} = Communities.get_proposal(proposal.id)
      assert updated.status == "pending"
    end

    test "page owner can reject proposal", %{
      conn: conn,
      owner: owner,
      community: community,
      page: page,
      proposal: proposal
    } do
      {:ok, lv, _html} =
        conn
        |> log_in_user(owner)
        |> live(~p"/c/#{community.name}/#{page.slug}/proposals/#{proposal.id}")

      render_click(lv, "reject")
      assert_redirect(lv, ~p"/dashboard")

      {:ok, updated} = Communities.get_proposal(proposal.id)
      assert updated.status == "rejected"
    end

    test "already-reviewed proposal cannot be approved again", %{
      conn: conn,
      owner: owner,
      community: community,
      page: page,
      proposal: proposal
    } do
      # Approve the proposal first
      {:ok, _} = Communities.approve_proposal(proposal, owner)

      # Visit the proposal page
      {:ok, lv, _html} =
        conn
        |> log_in_user(owner)
        |> live(~p"/c/#{community.name}/#{page.slug}/proposals/#{proposal.id}")

      # Try to approve again - should not change status
      render_click(lv, "approve")

      {:ok, updated} = Communities.get_proposal(proposal.id)
      assert updated.status == "approved"
    end

    test "community owner can approve page proposal", %{
      conn: conn,
      owner: owner,
      community: community,
      page_proposal: page_proposal
    } do
      {:ok, lv, _html} =
        conn
        |> log_in_user(owner)
        |> live(~p"/c/#{community.name}/page-proposals/#{page_proposal.id}")

      render_click(lv, "approve")

      {path, _flash} = assert_redirect(lv)

      {:ok, updated} = Communities.get_proposal(page_proposal.id)
      assert updated.status == "approved"
      # Page proposal approval creates a new page and redirects to it
      assert path =~ "/c/#{community.name}/"
    end
  end
end
