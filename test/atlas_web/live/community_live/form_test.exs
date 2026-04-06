defmodule AtlasWeb.CommunityLive.FormTest do
  use AtlasWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Atlas.AccountsFixtures

  describe "access control" do
    test "anonymous user is redirected to login", %{conn: conn} do
      assert {:error, {:redirect, %{to: path, flash: flash}}} =
               live(conn, ~p"/communities/new")

      assert path == ~p"/users/log-in"
      assert flash["error"] == "You must log in to access this page."
    end

    test "authenticated user can access new community form", %{conn: conn} do
      user = user_fixture()
      {:ok, _lv, html} = conn |> log_in_user(user) |> live(~p"/communities/new")

      assert html =~ "New Community"
    end
  end

  describe "community creation" do
    test "validate shows errors for invalid name", %{conn: conn} do
      user = user_fixture()
      {:ok, lv, _html} = conn |> log_in_user(user) |> live(~p"/communities/new")

      html =
        lv
        |> form("form[phx-submit=save]", %{"community" => %{"name" => "has spaces"}})
        |> render_change()

      assert html =~ "can only contain"
    end

    test "save creates community and redirects", %{conn: conn} do
      user = user_fixture()
      {:ok, lv, _html} = conn |> log_in_user(user) |> live(~p"/communities/new")

      community_name = "TestCommunity#{System.unique_integer([:positive])}"

      lv
      |> form("form[phx-submit=save]", %{
        "community" => %{"name" => community_name, "description" => "A test community"}
      })
      |> render_submit()

      assert_redirect(lv, ~p"/c/#{community_name}")
    end
  end
end
