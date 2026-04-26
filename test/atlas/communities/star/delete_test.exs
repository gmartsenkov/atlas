defmodule Atlas.Communities.Star.DeleteTest do
  use Atlas.DataCase, async: true

  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  alias Atlas.Communities.Star.{Create, Delete}
  alias Atlas.Communities.Stars

  setup do
    owner = user_fixture()
    community = community_fixture(owner)
    page = page_fixture(community, owner)

    %{owner: owner, page: page}
  end

  describe "call/2" do
    test "user can unstar a page", %{page: page} do
      user = user_fixture()
      {:ok, _} = Create.call(user, page)

      assert :ok = Delete.call(user, page)
      refute Stars.page_starred?(user, page)
    end

    test "unstarring a page that isn't starred is a no-op", %{page: page} do
      user = user_fixture()

      assert :ok = Delete.call(user, page)
    end
  end
end
