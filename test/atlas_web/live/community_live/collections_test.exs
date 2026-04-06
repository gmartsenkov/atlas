defmodule AtlasWeb.CommunityLive.CollectionsTest do
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
    test "owner can access collections", %{conn: conn, owner: owner, community: community} do
      {:ok, _lv, html} =
        conn |> log_in_user(owner) |> live(~p"/c/#{community.name}/collections")

      assert html =~ "Collections"
    end

    test "moderator can access collections", %{
      conn: conn,
      moderator: moderator,
      community: community
    } do
      {:ok, _lv, html} =
        conn |> log_in_user(moderator) |> live(~p"/c/#{community.name}/collections")

      assert html =~ "Collections"
    end

    test "member is redirected", %{conn: conn, member: member, community: community} do
      assert {:error, {:live_redirect, %{to: path, flash: flash}}} =
               conn |> log_in_user(member) |> live(~p"/c/#{community.name}/collections")

      assert path == ~p"/c/#{community.name}"
      assert flash["error"] == "You don't have permission to manage collections."
    end

    test "stranger is redirected", %{conn: conn, stranger: stranger, community: community} do
      assert {:error, {:live_redirect, %{to: path, flash: flash}}} =
               conn |> log_in_user(stranger) |> live(~p"/c/#{community.name}/collections")

      assert path == ~p"/c/#{community.name}"
      assert flash["error"] == "You don't have permission to manage collections."
    end

    test "anonymous user is redirected to login", %{conn: conn, community: community} do
      assert {:error, {:redirect, %{to: path, flash: flash}}} =
               live(conn, ~p"/c/#{community.name}/collections")

      assert path == ~p"/users/log-in"
      assert flash["error"] == "You must log in to access this page."
    end
  end

  describe "collection management" do
    test "can create a collection", %{conn: conn, owner: owner, community: community} do
      {:ok, lv, _html} =
        conn |> log_in_user(owner) |> live(~p"/c/#{community.name}/collections")

      html = render_submit(lv, "create-collection", %{"name" => "My Collection"})
      assert html =~ "My Collection"
    end

    test "can delete a collection", %{conn: conn, owner: owner, community: community} do
      collection = collection_fixture(community, %{"name" => "To Delete"})

      {:ok, lv, html} =
        conn |> log_in_user(owner) |> live(~p"/c/#{community.name}/collections")

      assert html =~ "To Delete"

      render_click(lv, "delete-collection", %{"id" => to_string(collection.id)})
      html = render(lv)
      refute html =~ "To Delete"
    end
  end
end
