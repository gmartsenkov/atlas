defmodule AtlasWeb.PageLive.ProposeTest do
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

    page = page_fixture(community, owner)
    [section | _] = Communities.list_sections(page.id)

    %{
      owner: owner,
      member: member,
      community: community,
      page: page,
      section: section,
      conn: conn
    }
  end

  describe "access control" do
    test "member can access propose page when suggestions enabled", %{
      conn: conn,
      member: member,
      community: community,
      page: page,
      section: section
    } do
      {:ok, _lv, html} =
        conn
        |> log_in_user(member)
        |> live(~p"/c/#{community.name}/#{page.slug}/sections/#{section.id}/propose")

      assert html =~ "Propose Edit"
    end

    test "redirects when suggestions are disabled", %{
      conn: conn,
      member: member
    } do
      disabled_owner = user_fixture()
      disabled_community = community_fixture(disabled_owner, %{"suggestions_enabled" => false})
      disabled_page = page_fixture(disabled_community, disabled_owner)
      [disabled_section | _] = Communities.list_sections(disabled_page.id)

      assert {:error, {:live_redirect, %{to: path, flash: flash}}} =
               conn
               |> log_in_user(member)
               |> live(
                 ~p"/c/#{disabled_community.name}/#{disabled_page.slug}/sections/#{disabled_section.id}/propose"
               )

      assert path == ~p"/c/#{disabled_community.name}/#{disabled_page.slug}"
      assert flash["error"] == "Suggestions are disabled for this community."
    end

    test "anonymous user is redirected to login", %{
      conn: conn,
      community: community,
      page: page,
      section: section
    } do
      assert {:error, {:redirect, %{to: path}}} =
               live(
                 conn,
                 ~p"/c/#{community.name}/#{page.slug}/sections/#{section.id}/propose"
               )

      assert path == ~p"/users/log-in"
    end

    test "nonexistent section raises 404", %{
      conn: conn,
      member: member,
      community: community,
      page: page
    } do
      assert_raise AtlasWeb.NotFoundError, fn ->
        conn
        |> log_in_user(member)
        |> live(~p"/c/#{community.name}/#{page.slug}/sections/999999/propose")
      end
    end
  end

  describe "submitting proposal" do
    test "member can submit a section proposal", %{
      conn: conn,
      member: member,
      community: community,
      page: page,
      section: section
    } do
      {:ok, lv, _html} =
        conn
        |> log_in_user(member)
        |> live(~p"/c/#{community.name}/#{page.slug}/sections/#{section.id}/propose")

      new_content = [
        %{
          "type" => "paragraph",
          "content" => [%{"type" => "text", "text" => "My proposed change"}],
          "children" => []
        }
      ]

      render_hook(lv, "editor-updated", %{"blocks" => new_content})
      render_click(lv, "submit-proposal")

      assert_redirect(lv, ~p"/c/#{community.name}/#{page.slug}")
    end
  end
end
