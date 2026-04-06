defmodule AtlasWeb.ProposalLive.EditTest do
  use AtlasWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  alias Atlas.Communities

  setup %{conn: conn} do
    owner = user_fixture()
    community = community_fixture(owner, %{"suggestions_enabled" => true})
    author = user_fixture()
    Communities.join_community(author, community)
    moderator = user_fixture()
    Communities.join_community(moderator, community)
    Communities.set_member_role(community, moderator.id, "moderator")
    stranger = user_fixture()
    Communities.join_community(stranger, community)

    page = page_fixture(community, owner)
    [section | _] = Communities.list_sections(page.id)
    proposal = proposal_fixture(section, author)
    page_proposal = page_proposal_fixture(community, author)

    %{
      owner: owner,
      author: author,
      moderator: moderator,
      stranger: stranger,
      community: community,
      page: page,
      section: section,
      proposal: proposal,
      page_proposal: page_proposal,
      conn: conn
    }
  end

  describe "section proposal edit access" do
    test "author can access edit page", %{
      conn: conn,
      author: author,
      community: community,
      page: page,
      proposal: proposal
    } do
      {:ok, _lv, html} =
        conn
        |> log_in_user(author)
        |> live(~p"/c/#{community.name}/#{page.slug}/proposals/#{proposal.id}/edit")

      assert html =~ "Edit Proposal"
    end

    test "community owner can access edit page", %{
      conn: conn,
      owner: owner,
      community: community,
      page: page,
      proposal: proposal
    } do
      {:ok, _lv, html} =
        conn
        |> log_in_user(owner)
        |> live(~p"/c/#{community.name}/#{page.slug}/proposals/#{proposal.id}/edit")

      assert html =~ "Edit Proposal"
    end

    test "moderator can access edit page", %{
      conn: conn,
      moderator: moderator,
      community: community,
      page: page,
      proposal: proposal
    } do
      {:ok, _lv, html} =
        conn
        |> log_in_user(moderator)
        |> live(~p"/c/#{community.name}/#{page.slug}/proposals/#{proposal.id}/edit")

      assert html =~ "Edit Proposal"
    end

    test "other member is redirected", %{
      conn: conn,
      stranger: stranger,
      community: community,
      page: page,
      proposal: proposal
    } do
      assert {:error, {:live_redirect, %{to: path, flash: flash}}} =
               conn
               |> log_in_user(stranger)
               |> live(~p"/c/#{community.name}/#{page.slug}/proposals/#{proposal.id}/edit")

      assert path =~ "/proposals/#{proposal.id}"
      assert flash["error"] == "You don't have permission to edit this proposal."
    end

    test "anonymous user is redirected to login", %{
      conn: conn,
      community: community,
      page: page,
      proposal: proposal
    } do
      assert {:error, {:redirect, %{to: path}}} =
               live(conn, ~p"/c/#{community.name}/#{page.slug}/proposals/#{proposal.id}/edit")

      assert path == ~p"/users/log-in"
    end
  end

  describe "page proposal edit access" do
    test "author can access page proposal edit", %{
      conn: conn,
      author: author,
      community: community,
      page_proposal: page_proposal
    } do
      {:ok, _lv, html} =
        conn
        |> log_in_user(author)
        |> live(~p"/c/#{community.name}/page-proposals/#{page_proposal.id}/edit")

      assert html =~ "Edit Proposal"
    end

    test "other member is redirected from page proposal edit", %{
      conn: conn,
      stranger: stranger,
      community: community,
      page_proposal: page_proposal
    } do
      assert {:error, {:live_redirect, %{to: path, flash: flash}}} =
               conn
               |> log_in_user(stranger)
               |> live(~p"/c/#{community.name}/page-proposals/#{page_proposal.id}/edit")

      assert path =~ "/page-proposals/#{page_proposal.id}"
      assert flash["error"] == "You don't have permission to edit this proposal."
    end
  end

  describe "saving section proposal" do
    test "author can save proposal changes", %{
      conn: conn,
      author: author,
      community: community,
      page: page,
      proposal: proposal
    } do
      {:ok, lv, _html} =
        conn
        |> log_in_user(author)
        |> live(~p"/c/#{community.name}/#{page.slug}/proposals/#{proposal.id}/edit")

      new_content = [
        %{
          "type" => "paragraph",
          "content" => [%{"type" => "text", "text" => "Updated proposal content"}],
          "children" => []
        }
      ]

      render_hook(lv, "editor-updated", %{"blocks" => new_content})
      render_click(lv, "save-proposal")

      assert_redirect(lv, ~p"/c/#{community.name}/#{page.slug}/proposals/#{proposal.id}")
    end
  end
end
