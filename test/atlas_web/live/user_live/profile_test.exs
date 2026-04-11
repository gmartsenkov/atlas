defmodule AtlasWeb.UserLive.ProfileTest do
  use AtlasWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Atlas.AccountsFixtures

  describe "report user" do
    test "authenticated user sees report button on another user's profile", %{conn: conn} do
      viewer = user_fixture()
      profile_user = user_fixture()

      {:ok, _lv, html} = conn |> log_in_user(viewer) |> live(~p"/u/#{profile_user.nickname}")

      assert html =~ "Report"
    end

    test "user does not see report button on own profile", %{conn: conn} do
      user = user_fixture()

      {:ok, _lv, html} = conn |> log_in_user(user) |> live(~p"/u/#{user.nickname}")

      refute html =~ "report-user"
    end

    test "anonymous user does not see report button", %{conn: conn} do
      profile_user = user_fixture()

      {:ok, _lv, html} = live(conn, ~p"/u/#{profile_user.nickname}")

      refute html =~ "report-user"
    end

    test "authenticated user can submit a report", %{conn: conn} do
      viewer = user_fixture()
      profile_user = user_fixture()

      {:ok, lv, _html} = conn |> log_in_user(viewer) |> live(~p"/u/#{profile_user.nickname}")

      render_click(lv, "report-user")
      assert render(lv) =~ "Report User"

      html = render_submit(lv, "submit-report", %{"reason" => "harassment", "details" => "Test"})

      assert html =~ "Report submitted"
    end

    test "user can cancel a report", %{conn: conn} do
      viewer = user_fixture()
      profile_user = user_fixture()

      {:ok, lv, _html} = conn |> log_in_user(viewer) |> live(~p"/u/#{profile_user.nickname}")

      render_click(lv, "report-user")
      assert render(lv) =~ "Report User"

      render_click(lv, "cancel-report")
      refute render(lv) =~ "Report User"
    end
  end
end
