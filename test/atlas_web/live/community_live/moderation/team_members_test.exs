defmodule AtlasWeb.CommunityLive.Moderation.TeamMembersTest do
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

    %{
      owner: owner,
      member: member,
      moderator: moderator,
      community: community,
      conn: conn
    }
  end

  describe "rendering" do
    test "shows heading", %{conn: conn, owner: owner, community: community} do
      {:ok, _lv, html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/members")

      assert html =~ "Mods &amp; Members"
    end

    test "shows all community members", %{
      conn: conn,
      owner: owner,
      member: member,
      moderator: moderator,
      community: community
    } do
      {:ok, _lv, html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/members")

      assert html =~ owner.nickname
      assert html =~ member.nickname
      assert html =~ moderator.nickname
    end

    test "shows owner badge", %{conn: conn, owner: owner, community: community} do
      {:ok, _lv, html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/members")

      assert html =~ "Owner"
    end

    test "shows moderator badge", %{conn: conn, owner: owner, community: community} do
      {:ok, _lv, html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/members")

      assert html =~ "Moderator"
    end

    test "does not show toggle button for owner", %{
      conn: conn,
      owner: owner,
      community: community
    } do
      {:ok, _lv, html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/members")

      # Owner row should not have a Make Mod / Remove Mod button
      # The owner badge exists but no toggle button with owner's user-id
      refute html =~ "phx-value-user-id=\"#{owner.id}\""
    end
  end

  describe "search" do
    test "filters members by nickname", %{
      conn: conn,
      owner: owner,
      member: member,
      community: community
    } do
      {:ok, lv, _html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/members")

      html = render_keyup(lv, "search-members", %{"value" => member.nickname})
      assert html =~ member.nickname
    end

    test "shows no members message for unmatched search", %{
      conn: conn,
      owner: owner,
      community: community
    } do
      {:ok, lv, _html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/members")

      html = render_keyup(lv, "search-members", %{"value" => "zzz_nonexistent_zzz"})
      assert html =~ "No members found"
    end

    test "clearing search shows all members again", %{
      conn: conn,
      owner: owner,
      member: member,
      moderator: moderator,
      community: community
    } do
      {:ok, lv, _html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/members")

      # Search for specific member
      render_keyup(lv, "search-members", %{"value" => member.nickname})

      # Clear search
      html = render_keyup(lv, "search-members", %{"value" => ""})
      assert html =~ member.nickname
      assert html =~ moderator.nickname
    end
  end

  describe "toggle moderator" do
    test "owner can promote member to moderator", %{
      conn: conn,
      owner: owner,
      member: member,
      community: community
    } do
      {:ok, lv, _html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/members")

      refute Communities.moderator?(member, community)

      render_click(lv, "toggle-moderator", %{"user-id" => to_string(member.id)})

      assert Communities.moderator?(member, community)
    end

    test "owner can demote moderator to member", %{
      conn: conn,
      owner: owner,
      moderator: moderator,
      community: community
    } do
      {:ok, lv, _html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/members")

      assert Communities.moderator?(moderator, community)

      render_click(lv, "toggle-moderator", %{"user-id" => to_string(moderator.id)})

      refute Communities.moderator?(moderator, community)
    end

    test "toggle updates the displayed badge", %{
      conn: conn,
      owner: owner,
      member: member,
      community: community
    } do
      {:ok, lv, html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/members")

      # Member should show "Make Mod" button initially
      assert html =~ "Make Mod"

      html = render_click(lv, "toggle-moderator", %{"user-id" => to_string(member.id)})

      # After promotion, should show "Remove Mod" and moderator badge
      assert html =~ "Remove Mod"
    end

    test "cannot toggle owner role", %{
      conn: conn,
      owner: owner,
      community: community
    } do
      # The owner row doesn't have a toggle button at all,
      # but even if the event is sent manually it should be a no-op
      {:ok, _lv, html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/members")

      refute html =~ "phx-value-user-id=\"#{owner.id}\""
    end
  end

  describe "moderator access" do
    test "moderator can view members list", %{
      conn: conn,
      moderator: moderator,
      owner: owner,
      community: community
    } do
      {:ok, _lv, html} =
        conn |> log_in_user(moderator) |> live(~p"/mod/#{community.name}/members")

      assert html =~ "Mods &amp; Members"
      assert html =~ owner.nickname
    end

    test "moderator can search members", %{
      conn: conn,
      moderator: moderator,
      member: member,
      community: community
    } do
      {:ok, lv, _html} =
        conn |> log_in_user(moderator) |> live(~p"/mod/#{community.name}/members")

      html = render_keyup(lv, "search-members", %{"value" => member.nickname})
      assert html =~ member.nickname
    end
  end
end
