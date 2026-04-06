defmodule AtlasWeb.PageLive.ProposeNewTest do
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

    %{owner: owner, member: member, community: community, conn: conn}
  end

  describe "access control" do
    test "authenticated user can access when suggestions enabled", %{
      conn: conn,
      member: member,
      community: community
    } do
      {:ok, _lv, html} =
        conn |> log_in_user(member) |> live(~p"/c/#{community.name}/propose-page")

      assert html =~ "Propose New Page"
    end

    test "redirects when suggestions are disabled", %{conn: conn, member: member} do
      disabled_owner = user_fixture()
      disabled_community = community_fixture(disabled_owner, %{"suggestions_enabled" => false})

      assert {:error, {:live_redirect, %{to: path, flash: flash}}} =
               conn
               |> log_in_user(member)
               |> live(~p"/c/#{disabled_community.name}/propose-page")

      assert path == ~p"/c/#{disabled_community.name}"
      assert flash["error"] == "Suggestions are disabled for this community."
    end

    test "anonymous user is redirected to login", %{conn: conn, community: community} do
      assert {:error, {:redirect, %{to: path}}} =
               live(conn, ~p"/c/#{community.name}/propose-page")

      assert path == ~p"/users/log-in"
    end
  end

  describe "submitting page proposal" do
    test "member can submit a new page proposal", %{
      conn: conn,
      member: member,
      community: community
    } do
      {:ok, lv, _html} =
        conn |> log_in_user(member) |> live(~p"/c/#{community.name}/propose-page")

      # Set title (triggers slug generation)
      render_hook(lv, "validate", %{"value" => "My Proposed Page"})

      # Set content
      new_content = [
        %{
          "type" => "paragraph",
          "content" => [%{"type" => "text", "text" => "New page content"}],
          "children" => []
        }
      ]

      render_hook(lv, "editor-updated", %{"blocks" => new_content})
      render_click(lv, "submit-proposal")

      assert_redirect(lv, ~p"/c/#{community.name}")
    end
  end
end
