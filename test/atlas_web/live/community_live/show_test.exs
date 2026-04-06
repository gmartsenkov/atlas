defmodule AtlasWeb.CommunityLive.ShowTest do
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
    stranger = user_fixture()

    page = page_fixture(community, owner)

    %{
      owner: owner,
      member: member,
      moderator: moderator,
      stranger: stranger,
      community: community,
      page: page,
      conn: conn
    }
  end

  describe "rendering" do
    test "shows community and page content", %{conn: conn, community: community, page: page} do
      {:ok, _lv, html} = live(conn, ~p"/c/#{community.name}/#{page.slug}")

      assert html =~ community.name
      assert html =~ page.title
    end

    test "redirects to first page when no page_slug given", %{
      conn: conn,
      community: community,
      page: page
    } do
      assert {:error, {:live_redirect, %{to: path}}} =
               live(conn, ~p"/c/#{community.name}")

      assert path == ~p"/c/#{community.name}/#{page.slug}"
    end

    test "nonexistent community raises 404", %{conn: conn} do
      assert_raise AtlasWeb.NotFoundError, fn ->
        live(conn, ~p"/c/nonexistent_community_xyz")
      end
    end

    test "nonexistent page raises 404", %{conn: conn, community: community} do
      assert_raise AtlasWeb.NotFoundError, fn ->
        live(conn, ~p"/c/#{community.name}/no-such-page")
      end
    end

    test "empty community shows empty state", %{conn: conn, owner: owner} do
      empty_community = community_fixture(owner, %{"name" => "EmptyCommunity"})
      {:ok, _lv, html} = live(conn, ~p"/c/#{empty_community.name}")

      assert html =~ "No pages yet"
    end
  end

  describe "join/leave" do
    test "stranger can join community", %{
      conn: conn,
      stranger: stranger,
      community: community,
      page: page
    } do
      {:ok, lv, html} =
        conn |> log_in_user(stranger) |> live(~p"/c/#{community.name}/#{page.slug}")

      assert html =~ "Join"

      refute Communities.member?(stranger, community)
      render_click(lv, "join")
      assert Communities.member?(stranger, community)
    end

    test "member can leave community", %{
      conn: conn,
      member: member,
      community: community,
      page: page
    } do
      {:ok, lv, html} =
        conn |> log_in_user(member) |> live(~p"/c/#{community.name}/#{page.slug}")

      assert html =~ "Leave"

      render_click(lv, "leave")
      refute Communities.member?(member, community)
    end

    test "owner cannot leave community", %{
      conn: conn,
      owner: owner,
      community: community,
      page: page
    } do
      {:ok, lv, _html} =
        conn |> log_in_user(owner) |> live(~p"/c/#{community.name}/#{page.slug}")

      render_click(lv, "leave")

      # Owner should still be a member
      assert Communities.member?(owner, community)
    end
  end

  describe "star/unstar" do
    test "logged-in user can star and unstar a page", %{
      conn: conn,
      member: member,
      community: community,
      page: page
    } do
      {:ok, lv, _html} =
        conn |> log_in_user(member) |> live(~p"/c/#{community.name}/#{page.slug}")

      render_click(lv, "star")
      assert Communities.page_starred?(member, page)

      render_click(lv, "unstar")
      refute Communities.page_starred?(member, page)
    end
  end

  describe "UI authorization" do
    test "owner sees Edit and Collections links", %{
      conn: conn,
      owner: owner,
      community: community,
      page: page
    } do
      {:ok, _lv, html} =
        conn |> log_in_user(owner) |> live(~p"/c/#{community.name}/#{page.slug}")

      assert html =~ "/c/#{community.name}/edit"
      assert html =~ "/c/#{community.name}/collections"
    end

    test "moderator sees Collections but not Edit link", %{
      conn: conn,
      moderator: moderator,
      community: community,
      page: page
    } do
      {:ok, _lv, html} =
        conn |> log_in_user(moderator) |> live(~p"/c/#{community.name}/#{page.slug}")

      refute html =~ "/c/#{community.name}/edit"
      assert html =~ "/c/#{community.name}/collections"
    end

    test "regular member does not see Edit or Collections links", %{
      conn: conn,
      member: member,
      community: community,
      page: page
    } do
      {:ok, _lv, html} =
        conn |> log_in_user(member) |> live(~p"/c/#{community.name}/#{page.slug}")

      refute html =~ "/c/#{community.name}/edit"
      refute html =~ "/c/#{community.name}/collections"
    end

    test "anonymous user does not see Edit or Collections links", %{
      conn: conn,
      community: community,
      page: page
    } do
      {:ok, _lv, html} = live(conn, ~p"/c/#{community.name}/#{page.slug}")

      refute html =~ "/c/#{community.name}/edit"
      refute html =~ "/c/#{community.name}/collections"
    end
  end
end
