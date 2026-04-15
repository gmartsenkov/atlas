defmodule AtlasWeb.CommunityLive.Moderation.RestrictedUsersTest do
  use AtlasWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  alias Atlas.Communities.CommunityManager

  setup %{conn: conn} do
    owner = user_fixture()
    community = community_fixture(owner)
    moderator = user_fixture()
    CommunityManager.join_community(moderator, community)
    CommunityManager.set_member_role(community, moderator.id, "moderator")
    member = user_fixture()
    CommunityManager.join_community(member, community)
    target_user = user_fixture()

    %{
      owner: owner,
      community: community,
      moderator: moderator,
      member: member,
      target_user: target_user,
      conn: conn
    }
  end

  describe "access control" do
    test "regular member cannot access restricted users page", %{
      conn: conn,
      member: member,
      community: community
    } do
      assert {:error, {:live_redirect, %{flash: flash}}} =
               conn |> log_in_user(member) |> live(~p"/mod/#{community.name}/restricted")

      assert flash["error"] =~ "You don't have permission"
    end

    test "unauthenticated user is redirected", %{conn: conn, community: community} do
      assert {:error, {:redirect, _}} = live(conn, ~p"/mod/#{community.name}/restricted")
    end
  end

  describe "rendering" do
    test "shows heading and restrict button", %{conn: conn, owner: owner, community: community} do
      {:ok, _lv, html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/restricted")

      assert html =~ "Restricted Users"
      assert html =~ "Restrict User"
    end

    test "shows empty state when no restrictions", %{
      conn: conn,
      owner: owner,
      community: community
    } do
      {:ok, _lv, html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/restricted")

      assert html =~ "No restricted users"
    end

    test "shows existing restriction in table", %{
      conn: conn,
      owner: owner,
      community: community,
      target_user: target_user
    } do
      restriction_fixture(community, target_user, owner, %{reason: "Spamming everywhere"})

      {:ok, _lv, html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/restricted")

      assert html =~ target_user.nickname
      assert html =~ "Spamming everywhere"
      assert html =~ owner.nickname
      assert html =~ "Unrestrict"
    end

    test "shows dash when no reason", %{
      conn: conn,
      owner: owner,
      community: community,
      target_user: target_user
    } do
      restriction_fixture(community, target_user, owner)

      {:ok, _lv, html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/restricted")

      assert html =~ target_user.nickname
      refute html =~ "Spamming"
    end
  end

  describe "restrict user modal" do
    test "opens and closes modal", %{conn: conn, owner: owner, community: community} do
      {:ok, lv, html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/restricted")

      refute html =~ "modal-open"

      html = render_click(lv, "open-restrict-modal")
      assert html =~ "modal-open"
      assert html =~ "Search users by nickname"

      html = render_click(lv, "close-restrict-modal")
      refute html =~ "modal-open"
    end

    test "searches for users in modal", %{
      conn: conn,
      owner: owner,
      community: community,
      target_user: target_user
    } do
      {:ok, lv, _html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/restricted")

      render_click(lv, "open-restrict-modal")

      html = render_keyup(lv, "search-users", %{"value" => target_user.nickname})
      assert html =~ target_user.nickname
    end

    test "shows no users found for unmatched search", %{
      conn: conn,
      owner: owner,
      community: community
    } do
      {:ok, lv, _html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/restricted")

      render_click(lv, "open-restrict-modal")

      html = render_keyup(lv, "search-users", %{"value" => "zzz_nonexistent_zzz"})
      assert html =~ "No users found"
    end

    test "selects user and shows reason form", %{
      conn: conn,
      owner: owner,
      community: community,
      target_user: target_user
    } do
      {:ok, lv, _html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/restricted")

      render_click(lv, "open-restrict-modal")
      render_keyup(lv, "search-users", %{"value" => target_user.nickname})

      html = render_click(lv, "select-user", %{"id" => to_string(target_user.id)})

      assert html =~ target_user.nickname
      assert html =~ "Reason (optional)"
      assert html =~ "restrict-form"
    end

    test "clears selected user back to search", %{
      conn: conn,
      owner: owner,
      community: community,
      target_user: target_user
    } do
      {:ok, lv, _html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/restricted")

      render_click(lv, "open-restrict-modal")
      render_keyup(lv, "search-users", %{"value" => target_user.nickname})
      render_click(lv, "select-user", %{"id" => to_string(target_user.id)})

      html = render_click(lv, "clear-selected-user")

      assert html =~ "Search users by nickname"
      refute html =~ "restrict-form"
    end
  end

  describe "restrict action" do
    test "restricts a user with reason", %{
      conn: conn,
      owner: owner,
      community: community,
      target_user: target_user
    } do
      {:ok, lv, _html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/restricted")

      render_click(lv, "open-restrict-modal")
      render_keyup(lv, "search-users", %{"value" => target_user.nickname})
      render_click(lv, "select-user", %{"id" => to_string(target_user.id)})

      html = render_submit(lv, "save-restriction", %{"reason" => "Bad behavior"})

      assert html =~ "has been restricted"
      assert html =~ target_user.nickname
      assert html =~ "Bad behavior"
    end

    test "restricts a user without reason", %{
      conn: conn,
      owner: owner,
      community: community,
      target_user: target_user
    } do
      {:ok, lv, _html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/restricted")

      render_click(lv, "open-restrict-modal")
      render_keyup(lv, "search-users", %{"value" => target_user.nickname})
      render_click(lv, "select-user", %{"id" => to_string(target_user.id)})

      html = render_submit(lv, "save-restriction", %{"reason" => ""})

      assert html =~ "has been restricted"
      assert html =~ target_user.nickname
    end

    test "shows error when restricting already restricted user", %{
      conn: conn,
      owner: owner,
      community: community,
      target_user: target_user
    } do
      restriction_fixture(community, target_user, owner)

      {:ok, lv, _html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/restricted")

      render_click(lv, "open-restrict-modal")
      render_keyup(lv, "search-users", %{"value" => target_user.nickname})
      render_click(lv, "select-user", %{"id" => to_string(target_user.id)})

      html = render_submit(lv, "save-restriction", %{"reason" => ""})

      assert html =~ "already restricted"
    end
  end

  describe "unrestrict action" do
    test "removes restriction from list", %{
      conn: conn,
      owner: owner,
      community: community,
      target_user: target_user
    } do
      restriction = restriction_fixture(community, target_user, owner, %{reason: "Test"})

      {:ok, lv, html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/restricted")

      assert html =~ target_user.nickname

      html = render_click(lv, "unrestrict", %{"id" => to_string(restriction.id)})

      assert html =~ "has been unrestricted"
      refute html =~ target_user.nickname
    end
  end

  describe "pagination" do
    test "does not show load more button when under per_page limit", %{
      conn: conn,
      owner: owner,
      community: community,
      target_user: target_user
    } do
      restriction_fixture(community, target_user, owner)

      {:ok, _lv, html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/restricted")

      refute html =~ "Load more"
    end

    test "shows load more button and loads next page", %{
      conn: conn,
      owner: owner,
      community: community
    } do
      # Create 21 restrictions to exceed the @per_page of 20
      users = for _ <- 1..21, do: user_fixture()

      for user <- users do
        restriction_fixture(community, user, owner)
      end

      {:ok, lv, html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/restricted")

      assert html =~ "Load more"
      assert html =~ "1 remaining"

      # The last user (most recent, shown on page 2) shouldn't be visible yet
      # since ordering is desc by inserted_at, the first created user is last
      first_user = hd(users)
      refute html =~ first_user.nickname

      # Click load more to get the remaining item
      html = render_click(lv, "load-more-restrictions")
      assert html =~ first_user.nickname
      refute html =~ "Load more"
    end
  end

  describe "moderator access" do
    test "moderator can view restricted users", %{
      conn: conn,
      owner: owner,
      moderator: moderator,
      community: community,
      target_user: target_user
    } do
      restriction_fixture(community, target_user, owner)

      {:ok, _lv, html} =
        conn |> log_in_user(moderator) |> live(~p"/mod/#{community.name}/restricted")

      assert html =~ "Restricted Users"
      assert html =~ target_user.nickname
    end

    test "moderator can restrict a user", %{
      conn: conn,
      moderator: moderator,
      community: community,
      target_user: target_user
    } do
      {:ok, lv, _html} =
        conn |> log_in_user(moderator) |> live(~p"/mod/#{community.name}/restricted")

      render_click(lv, "open-restrict-modal")
      render_keyup(lv, "search-users", %{"value" => target_user.nickname})
      render_click(lv, "select-user", %{"id" => to_string(target_user.id)})

      html = render_submit(lv, "save-restriction", %{"reason" => "Spamming"})

      assert html =~ "has been restricted"
      assert html =~ target_user.nickname
    end
  end
end
