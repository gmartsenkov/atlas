defmodule AtlasWeb.PageLive.FormTest do
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
    test "owner can access new page form", %{conn: conn, owner: owner, community: community} do
      {:ok, _lv, html} =
        conn |> log_in_user(owner) |> live(~p"/c/#{community.name}/new")

      assert html =~ "New Page"
    end

    test "moderator can access new page form", %{
      conn: conn,
      moderator: moderator,
      community: community
    } do
      {:ok, _lv, html} =
        conn |> log_in_user(moderator) |> live(~p"/c/#{community.name}/new")

      assert html =~ "New Page"
    end

    test "member is redirected", %{conn: conn, member: member, community: community} do
      assert {:error, {:live_redirect, %{to: path, flash: flash}}} =
               conn |> log_in_user(member) |> live(~p"/c/#{community.name}/new")

      assert path == ~p"/c/#{community.name}"
      assert flash["error"] == "You don't have permission to create pages."
    end

    test "stranger is redirected", %{conn: conn, stranger: stranger, community: community} do
      assert {:error, {:live_redirect, %{to: path, flash: flash}}} =
               conn |> log_in_user(stranger) |> live(~p"/c/#{community.name}/new")

      assert path == ~p"/c/#{community.name}"
      assert flash["error"] == "You don't have permission to create pages."
    end

    test "anonymous user is redirected to login", %{conn: conn, community: community} do
      assert {:error, {:redirect, %{to: path, flash: flash}}} =
               live(conn, ~p"/c/#{community.name}/new")

      assert path == ~p"/users/log-in"
      assert flash["error"] == "You must log in to access this page."
    end
  end

  describe "page creation" do
    test "validate auto-generates slug from title", %{
      conn: conn,
      owner: owner,
      community: community
    } do
      {:ok, lv, _html} =
        conn |> log_in_user(owner) |> live(~p"/c/#{community.name}/new")

      html =
        lv
        |> form("form[phx-submit=save]", %{"page" => %{"title" => "My New Page"}})
        |> render_change()

      assert html =~ "my-new-page"
    end

    test "save creates page and redirects to editor", %{
      conn: conn,
      owner: owner,
      community: community
    } do
      {:ok, lv, _html} =
        conn |> log_in_user(owner) |> live(~p"/c/#{community.name}/new")

      lv
      |> form("form[phx-submit=save]", %{"page" => %{"title" => "Brand New Page"}})
      |> render_submit()

      assert_redirect(lv, ~p"/c/#{community.name}/brand-new-page/edit")
    end
  end
end
