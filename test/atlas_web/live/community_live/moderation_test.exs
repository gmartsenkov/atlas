defmodule AtlasWeb.CommunityLive.ModerationTest do
  @moduledoc """
  Tests for the shared moderation on_mount hook and access control.
  All three moderation LiveViews share the same :ensure_moderator hook,
  so access control is tested here once via the default /mod/:name route.
  """
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
    stranger = user_fixture()

    %{
      owner: owner,
      member: member,
      moderator: moderator,
      stranger: stranger,
      community: community,
      conn: conn
    }
  end

  describe "access control" do
    test "owner can access moderation area", %{conn: conn, owner: owner, community: community} do
      {:ok, _lv, html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}")

      assert html =~ "Proposal Queues"
    end

    test "moderator can access moderation area", %{
      conn: conn,
      moderator: moderator,
      community: community
    } do
      {:ok, _lv, html} =
        conn |> log_in_user(moderator) |> live(~p"/mod/#{community.name}")

      assert html =~ "Proposal Queues"
    end

    test "member is redirected", %{conn: conn, member: member, community: community} do
      assert {:error, {:live_redirect, %{to: path, flash: flash}}} =
               conn |> log_in_user(member) |> live(~p"/mod/#{community.name}")

      assert path == ~p"/c/#{community.name}"
      assert flash["error"] == "You don't have permission to moderate this community."
    end

    test "stranger is redirected", %{conn: conn, stranger: stranger, community: community} do
      assert {:error, {:live_redirect, %{to: path, flash: flash}}} =
               conn |> log_in_user(stranger) |> live(~p"/mod/#{community.name}")

      assert path == ~p"/c/#{community.name}"
      assert flash["error"] == "You don't have permission to moderate this community."
    end

    test "anonymous user is redirected to login", %{conn: conn, community: community} do
      assert {:error, {:redirect, %{to: path, flash: flash}}} =
               live(conn, ~p"/mod/#{community.name}")

      assert path == ~p"/users/log-in"
      assert flash["error"] == "You must log in to access this page."
    end

    test "nonexistent community raises 404", %{conn: conn, owner: owner} do
      assert_raise AtlasWeb.NotFoundError, fn ->
        conn |> log_in_user(owner) |> live(~p"/mod/nonexistent_community")
      end
    end

    test "member cannot access any mod tab directly", %{
      conn: conn,
      member: member,
      community: community
    } do
      for path <- [
            ~p"/mod/#{community.name}/queues",
            ~p"/mod/#{community.name}/members",
            ~p"/mod/#{community.name}/settings"
          ] do
        assert {:error, {:live_redirect, %{flash: flash}}} =
                 conn |> log_in_user(member) |> live(path)

        assert flash["error"] == "You don't have permission to moderate this community."
      end
    end
  end

  describe "sidebar" do
    test "owner sees all three sidebar links", %{
      conn: conn,
      owner: owner,
      community: community
    } do
      {:ok, _lv, html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}")

      assert html =~ "Queues"
      assert html =~ "Mods &amp; Members"
      assert html =~ "General Settings"
    end

    test "moderator does not see settings link", %{
      conn: conn,
      moderator: moderator,
      community: community
    } do
      {:ok, _lv, html} =
        conn |> log_in_user(moderator) |> live(~p"/mod/#{community.name}")

      assert html =~ "Queues"
      assert html =~ "Mods &amp; Members"
      refute html =~ "General Settings"
    end

    test "sidebar links point to correct routes", %{
      conn: conn,
      owner: owner,
      community: community
    } do
      {:ok, _lv, html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}")

      assert html =~ ~s|href="/mod/#{community.name}/queues"|
      assert html =~ ~s|href="/mod/#{community.name}/members"|
      assert html =~ ~s|href="/mod/#{community.name}/settings"|
    end

    test "sidebar shows community name with link back", %{
      conn: conn,
      owner: owner,
      community: community
    } do
      {:ok, _lv, html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}")

      assert html =~ community.name
      assert html =~ ~s|href="/c/#{community.name}"|
    end
  end
end
