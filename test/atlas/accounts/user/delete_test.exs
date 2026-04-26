defmodule Atlas.Accounts.User.DeleteTest do
  use Atlas.DataCase, async: true

  import Atlas.AccountsFixtures

  alias Atlas.Accounts.User.Delete

  setup do
    %{user: user_fixture()}
  end

  describe "call/2" do
    test "deletes user when nickname matches", %{user: user} do
      assert {:ok, _} = Delete.call(user, user.nickname)
    end

    test "returns error when nickname does not match", %{user: user} do
      assert {:error, :nickname_mismatch} = Delete.call(user, "wrong-name")
    end
  end
end
