defmodule AtlasWeb.ProposalLive.ShowTest do
  use AtlasWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  alias Atlas.Communities.CommunityManager
  alias Atlas.Communities.Proposals
  alias Atlas.Communities.Sections

  # Ensure :best atom exists for CommentsSection sort
  _ = :best

  setup %{conn: conn} do
    owner = user_fixture()
    community = community_fixture(owner, %{"suggestions_enabled" => true})
    member = user_fixture()
    CommunityManager.join_community(member, community)
    moderator = user_fixture()
    CommunityManager.join_community(moderator, community)
    CommunityManager.set_member_role(community, moderator.id, "moderator")
    other_member = user_fixture()
    CommunityManager.join_community(other_member, community)

    page = page_fixture(community, owner)
    [section | _] = Sections.list_sections(page.id)
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
      assert_redirect(lv, ~p"/mod/#{community.name}/proposals")

      {:ok, updated} = Proposals.get_proposal(proposal.id)
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
      assert_redirect(lv, ~p"/mod/#{community.name}/proposals")

      {:ok, updated} = Proposals.get_proposal(proposal.id)
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

      {:ok, updated} = Proposals.get_proposal(proposal.id)
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

      {:ok, updated} = Proposals.get_proposal(proposal.id)
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
      assert_redirect(lv, ~p"/mod/#{community.name}/proposals")

      {:ok, updated} = Proposals.get_proposal(proposal.id)
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
      {:ok, _} = Proposals.approve_proposal(proposal, owner)

      # Visit the proposal page
      {:ok, lv, _html} =
        conn
        |> log_in_user(owner)
        |> live(~p"/c/#{community.name}/#{page.slug}/proposals/#{proposal.id}")

      # Try to approve again - should not change status
      render_click(lv, "approve")

      {:ok, updated} = Proposals.get_proposal(proposal.id)
      assert updated.status == "approved"
    end

    test "moderator can reject proposal", %{
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

      render_click(lv, "reject")
      assert_redirect(lv, ~p"/mod/#{community.name}/proposals")

      {:ok, updated} = Proposals.get_proposal(proposal.id)
      assert updated.status == "rejected"
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

      {:ok, updated} = Proposals.get_proposal(page_proposal.id)
      assert updated.status == "approved"
      # Page proposal approval creates a new page and redirects to it
      assert path =~ "/c/#{community.name}/"
    end
  end

  describe "diff view" do
    test "section proposal defaults to diff view", %{
      conn: conn,
      member: member,
      community: community,
      page: page,
      proposal: proposal
    } do
      {:ok, _lv, html} =
        conn
        |> log_in_user(member)
        |> live(~p"/c/#{community.name}/#{page.slug}/proposals/#{proposal.id}")

      # Diff button should be active (has shadow-sm)
      assert html =~ "Diff"
      # Default section content is empty, so all proposed blocks show as insertions
      assert html =~ "bg-success/10"
      assert html =~ "Proposed change"
    end

    test "diff view shows added blocks in green when old content is empty", %{
      conn: conn,
      member: member,
      community: community,
      page: page,
      section: section
    } do
      proposal =
        proposal_fixture(section, member, %{
          proposed_content: [
            %{
              "type" => "heading",
              "props" => %{"level" => 1},
              "content" => [%{"type" => "text", "text" => "New Heading"}],
              "children" => []
            },
            %{
              "type" => "paragraph",
              "content" => [%{"type" => "text", "text" => "New paragraph"}],
              "children" => []
            }
          ]
        })

      {:ok, _lv, html} =
        conn
        |> log_in_user(member)
        |> live(~p"/c/#{community.name}/#{page.slug}/proposals/#{proposal.id}")

      # All blocks should be marked as insertions
      assert html =~ "bg-success/10"
      assert html =~ "New Heading"
      assert html =~ "New paragraph"
    end

    test "diff view shows removed blocks in red when new content is empty", %{
      conn: conn,
      member: member,
      community: community,
      page: page
    } do
      existing_content = [
        %{
          "type" => "paragraph",
          "content" => [%{"type" => "text", "text" => "Existing content"}],
          "children" => []
        }
      ]

      section = section_fixture(page, %{content: existing_content, sort_order: 10})

      proposal =
        proposal_fixture(section, member, %{
          proposed_content: []
        })

      {:ok, _lv, html} =
        conn
        |> log_in_user(member)
        |> live(~p"/c/#{community.name}/#{page.slug}/proposals/#{proposal.id}")

      # Block should be marked as deletion
      assert html =~ "bg-error/10"
      assert html =~ "Existing content"
    end

    test "diff view shows word-level changes for modified blocks", %{
      conn: conn,
      member: member,
      community: community,
      page: page
    } do
      existing_content = [
        %{
          "type" => "paragraph",
          "content" => [%{"type" => "text", "text" => "Hello world"}],
          "children" => []
        }
      ]

      section = section_fixture(page, %{content: existing_content, sort_order: 11})

      proposal =
        proposal_fixture(section, member, %{
          proposed_content: [
            %{
              "type" => "paragraph",
              "content" => [%{"type" => "text", "text" => "Hello earth"}],
              "children" => []
            }
          ]
        })

      {:ok, _lv, html} =
        conn
        |> log_in_user(member)
        |> live(~p"/c/#{community.name}/#{page.slug}/proposals/#{proposal.id}")

      # Modified block should show word-level diff
      assert html =~ "bg-warning/5"
      # Deleted word
      assert html =~ "bg-error/20"
      assert html =~ "world"
      # Inserted word
      assert html =~ "bg-success/20"
      assert html =~ "earth"
    end

    test "diff view can switch to other modes", %{
      conn: conn,
      member: member,
      community: community,
      page: page,
      proposal: proposal
    } do
      {:ok, lv, _html} =
        conn
        |> log_in_user(member)
        |> live(~p"/c/#{community.name}/#{page.slug}/proposals/#{proposal.id}")

      # Switch to proposed view
      html = render_click(lv, "toggle-view", %{"mode" => "proposed"})
      refute html =~ "bg-success/10"
      assert html =~ "Proposed change"

      # Switch to side-by-side view
      html = render_click(lv, "toggle-view", %{"mode" => "side-by-side"})
      assert html =~ "Current"
      assert html =~ "Proposed"

      # Switch back to diff
      html = render_click(lv, "toggle-view", %{"mode" => "diff"})
      assert html =~ "bg-success/10"
    end

    test "page proposal does not show diff button", %{
      conn: conn,
      member: member,
      community: community,
      page_proposal: page_proposal
    } do
      {:ok, _lv, html} =
        conn
        |> log_in_user(member)
        |> live(~p"/c/#{community.name}/page-proposals/#{page_proposal.id}")

      # Page proposals have no "before" so no diff/current/side-by-side buttons
      refute html =~ "Diff"
      refute html =~ "Current"
      refute html =~ "Side by Side"
    end

    test "diff view shows no changes for identical content", %{
      conn: conn,
      member: member,
      community: community,
      page: page
    } do
      content = [
        %{
          "type" => "paragraph",
          "content" => [%{"type" => "text", "text" => "Same content"}],
          "children" => []
        }
      ]

      section = section_fixture(page, %{content: content, sort_order: 12})
      proposal = proposal_fixture(section, member, %{proposed_content: content})

      {:ok, _lv, html} =
        conn
        |> log_in_user(member)
        |> live(~p"/c/#{community.name}/#{page.slug}/proposals/#{proposal.id}")

      # No diff markers for identical content
      refute html =~ "bg-success/10"
      refute html =~ "bg-error/10"
      refute html =~ "bg-warning/5"
      # But the content should still render
      assert html =~ "Same content"
    end
  end
end
