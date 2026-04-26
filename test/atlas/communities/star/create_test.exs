defmodule Atlas.Communities.Star.CreateTest do
  use Atlas.DataCase, async: true

  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  alias Atlas.Communities.Star.Create
  alias Atlas.Communities.Stars

  setup do
    owner = user_fixture()
    community = community_fixture(owner)
    page = page_fixture(community, owner)

    %{owner: owner, page: page}
  end

  describe "call/2" do
    test "user can star a page", %{page: page} do
      user = user_fixture()

      assert {:ok, _} = Create.call(user, page)
      assert Stars.page_starred?(user, page)
    end

    test "starring the same page twice returns error", %{page: page} do
      user = user_fixture()

      assert {:ok, _} = Create.call(user, page)
      assert {:error, _} = Create.call(user, page)
    end
  end
end
