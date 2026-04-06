defmodule AtlasWeb.CommunityLive.EditTest do
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
    test "owner can access edit page", %{conn: conn, owner: owner, community: community} do
      {:ok, _lv, html} =
        conn |> log_in_user(owner) |> live(~p"/c/#{community.name}/edit")

      assert html =~ "Edit #{community.name}"
    end

    test "moderator is redirected", %{conn: conn, moderator: moderator, community: community} do
      assert {:error, {:live_redirect, %{to: path, flash: flash}}} =
               conn |> log_in_user(moderator) |> live(~p"/c/#{community.name}/edit")

      assert path == ~p"/c/#{community.name}"
      assert flash["error"] == "Only the community owner can edit this community."
    end

    test "member is redirected", %{conn: conn, member: member, community: community} do
      assert {:error, {:live_redirect, %{to: path, flash: flash}}} =
               conn |> log_in_user(member) |> live(~p"/c/#{community.name}/edit")

      assert path == ~p"/c/#{community.name}"
      assert flash["error"] == "Only the community owner can edit this community."
    end

    test "stranger is redirected", %{conn: conn, stranger: stranger, community: community} do
      assert {:error, {:live_redirect, %{to: path, flash: flash}}} =
               conn |> log_in_user(stranger) |> live(~p"/c/#{community.name}/edit")

      assert path == ~p"/c/#{community.name}"
      assert flash["error"] == "Only the community owner can edit this community."
    end

    test "anonymous user is redirected to login", %{conn: conn, community: community} do
      assert {:error, {:redirect, %{to: path, flash: flash}}} =
               live(conn, ~p"/c/#{community.name}/edit")

      assert path == ~p"/users/log-in"
      assert flash["error"] == "You must log in to access this page."
    end

    test "nonexistent community raises 404", %{conn: conn, owner: owner} do
      assert_raise AtlasWeb.NotFoundError, fn ->
        conn |> log_in_user(owner) |> live(~p"/c/nonexistent_community/edit")
      end
    end
  end

  describe "owner actions" do
    test "owner can update community", %{conn: conn, owner: owner, community: community} do
      {:ok, lv, _html} =
        conn |> log_in_user(owner) |> live(~p"/c/#{community.name}/edit")

      lv
      |> form("form[phx-submit=save]", %{"community" => %{"description" => "Updated description"}})
      |> render_submit()

      assert_redirect(lv, ~p"/c/#{community.name}")
    end

    test "owner can search members", %{
      conn: conn,
      owner: owner,
      member: member,
      community: community
    } do
      {:ok, lv, _html} =
        conn |> log_in_user(owner) |> live(~p"/c/#{community.name}/edit")

      html = render_change(lv, "search-members", %{"query" => member.nickname})
      assert html =~ member.nickname
    end

    test "owner can toggle moderator role", %{
      conn: conn,
      owner: owner,
      member: member,
      community: community
    } do
      {:ok, lv, _html} =
        conn |> log_in_user(owner) |> live(~p"/c/#{community.name}/edit")

      refute Communities.moderator?(member, community)

      render_change(lv, "search-members", %{"query" => member.nickname})
      render_click(lv, "toggle-moderator", %{"user-id" => to_string(member.id)})

      assert Communities.moderator?(member, community)
    end
  end
end
