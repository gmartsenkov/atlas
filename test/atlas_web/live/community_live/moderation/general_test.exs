defmodule AtlasWeb.CommunityLive.Moderation.GeneralTest do
  use AtlasWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  alias Atlas.Communities

  setup %{conn: conn} do
    owner = user_fixture()
    community = community_fixture(owner)
    moderator = user_fixture()
    Communities.join_community(moderator, community)
    Communities.set_member_role(community, moderator.id, "moderator")

    %{
      owner: owner,
      moderator: moderator,
      community: community,
      conn: conn
    }
  end

  describe "access control" do
    test "owner can access settings", %{conn: conn, owner: owner, community: community} do
      {:ok, _lv, html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/settings")

      assert html =~ "General Settings"
    end

    test "moderator is redirected to proposals", %{
      conn: conn,
      moderator: moderator,
      community: community
    } do
      assert {:error, {:live_redirect, %{to: path}}} =
               conn |> log_in_user(moderator) |> live(~p"/mod/#{community.name}/settings")

      assert path == ~p"/mod/#{community.name}/proposals"
    end
  end

  describe "rendering" do
    test "shows description field with current value", %{
      conn: conn,
      owner: owner,
      community: community
    } do
      {:ok, _lv, html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/settings")

      assert html =~ "Description"
      assert html =~ "Allow community suggestions"
    end

    test "shows logo upload area", %{conn: conn, owner: owner, community: community} do
      {:ok, _lv, html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/settings")

      assert html =~ "Click to upload an icon"
    end

    test "shows save and cancel buttons", %{conn: conn, owner: owner, community: community} do
      {:ok, _lv, html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/settings")

      assert html =~ "Save Changes"
      assert html =~ ~s|href="/c/#{community.name}"|
    end
  end

  describe "form validation" do
    test "validates on change", %{conn: conn, owner: owner, community: community} do
      {:ok, lv, _html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/settings")

      html =
        lv
        |> form("form[phx-submit=save]",
          community: %{description: "Updated via validate"}
        )
        |> render_change()

      assert html =~ "Updated via validate"
    end
  end

  describe "saving" do
    test "updates community description", %{
      conn: conn,
      owner: owner,
      community: community
    } do
      {:ok, lv, _html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/settings")

      lv
      |> form("form[phx-submit=save]",
        community: %{description: "A brand new description"}
      )
      |> render_submit()

      assert_redirect(lv, ~p"/mod/#{community.name}/settings")

      # Verify the change persisted
      {:ok, community} = Communities.get_community_by_name(community.name)
      assert community.description == "A brand new description"
    end

    test "toggles suggestions enabled", %{
      conn: conn,
      owner: owner,
      community: community
    } do
      {:ok, lv, _html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/settings")

      lv
      |> form("form[phx-submit=save]",
        community: %{suggestions_enabled: "false"}
      )
      |> render_submit()

      assert_redirect(lv, ~p"/mod/#{community.name}/settings")

      {:ok, community} = Communities.get_community_by_name(community.name)
      refute community.suggestions_enabled
    end

    test "shows success flash after save", %{
      conn: conn,
      owner: owner,
      community: community
    } do
      {:ok, lv, _html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/settings")

      lv
      |> form("form[phx-submit=save]",
        community: %{description: "New desc"}
      )
      |> render_submit()

      flash = assert_redirect(lv, ~p"/mod/#{community.name}/settings")
      assert flash["info"] == "Community updated successfully."
    end
  end

  describe "logo" do
    test "handles logo-uploaded event", %{conn: conn, owner: owner, community: community} do
      {:ok, lv, _html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/settings")

      html = render_hook(lv, "logo-uploaded", %{"url" => "https://example.com/logo.png"})
      assert html =~ "https://example.com/logo.png"
    end

    test "handles remove-logo event", %{conn: conn, owner: owner, community: community} do
      {:ok, lv, _html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/settings")

      # First set a logo
      render_hook(lv, "logo-uploaded", %{"url" => "https://example.com/logo.png"})

      # Then remove it
      html = render_click(lv, "remove-logo")
      refute html =~ "https://example.com/logo.png"
    end
  end
end
