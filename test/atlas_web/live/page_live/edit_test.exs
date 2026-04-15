defmodule AtlasWeb.PageLive.EditTest do
  use AtlasWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  alias Atlas.Communities.CommunityManager

  setup %{conn: conn} do
    owner = user_fixture()
    community = community_fixture(owner)
    member = user_fixture()
    CommunityManager.join_community(member, community)
    moderator = user_fixture()
    CommunityManager.join_community(moderator, community)
    CommunityManager.set_member_role(community, moderator.id, "moderator")
    stranger = user_fixture()

    page = page_fixture(community, owner)

    # Create a page owned by the member
    page_by_member = page_fixture(community, member, %{"title" => "Member Page"})

    %{
      owner: owner,
      member: member,
      moderator: moderator,
      stranger: stranger,
      community: community,
      page: page,
      page_by_member: page_by_member,
      conn: conn
    }
  end

  describe "access control" do
    test "community owner can access page editor", %{
      conn: conn,
      owner: owner,
      community: community,
      page: page
    } do
      {:ok, _lv, html} =
        conn |> log_in_user(owner) |> live(~p"/c/#{community.name}/#{page.slug}/edit")

      assert html =~ page.title
    end

    test "community owner can edit any page", %{
      conn: conn,
      owner: owner,
      community: community,
      page_by_member: page_by_member
    } do
      {:ok, _lv, html} =
        conn |> log_in_user(owner) |> live(~p"/c/#{community.name}/#{page_by_member.slug}/edit")

      assert html =~ page_by_member.title
    end

    test "moderator can access page editor", %{
      conn: conn,
      moderator: moderator,
      community: community,
      page: page
    } do
      {:ok, _lv, html} =
        conn |> log_in_user(moderator) |> live(~p"/c/#{community.name}/#{page.slug}/edit")

      assert html =~ page.title
    end

    test "page owner who is not a mod is redirected", %{
      conn: conn,
      member: member,
      community: community,
      page_by_member: page_by_member
    } do
      assert {:error, {:live_redirect, %{to: path, flash: flash}}} =
               conn
               |> log_in_user(member)
               |> live(~p"/c/#{community.name}/#{page_by_member.slug}/edit")

      assert path == ~p"/c/#{community.name}"
      assert flash["error"] == "You don't have permission to edit this page."
    end

    test "regular member is redirected", %{
      conn: conn,
      member: member,
      community: community,
      page: page
    } do
      assert {:error, {:live_redirect, %{to: path, flash: flash}}} =
               conn |> log_in_user(member) |> live(~p"/c/#{community.name}/#{page.slug}/edit")

      assert path == ~p"/c/#{community.name}"
      assert flash["error"] == "You don't have permission to edit this page."
    end

    test "stranger is redirected", %{
      conn: conn,
      stranger: stranger,
      community: community,
      page: page
    } do
      assert {:error, {:live_redirect, %{to: path, flash: flash}}} =
               conn
               |> log_in_user(stranger)
               |> live(~p"/c/#{community.name}/#{page.slug}/edit")

      assert path == ~p"/c/#{community.name}"
      assert flash["error"] == "You don't have permission to edit this page."
    end

    test "anonymous user is redirected to login", %{conn: conn, community: community, page: page} do
      assert {:error, {:redirect, %{to: path, flash: flash}}} =
               live(conn, ~p"/c/#{community.name}/#{page.slug}/edit")

      assert path == ~p"/users/log-in"
      assert flash["error"] == "You must log in to access this page."
    end

    test "nonexistent page raises 404", %{conn: conn, owner: owner, community: community} do
      assert_raise AtlasWeb.NotFoundError, fn ->
        conn |> log_in_user(owner) |> live(~p"/c/#{community.name}/nonexistent-page/edit")
      end
    end
  end
end
