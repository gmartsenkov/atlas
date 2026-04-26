defmodule Atlas.Accounts.User.ChangePasswordTest do
  use Atlas.DataCase, async: true

  import Atlas.AccountsFixtures

  alias Atlas.Accounts.User.ChangePassword

  setup do
    %{user: user_fixture()}
  end

  describe "call/3" do
    test "returns a changeset", %{user: user} do
      changeset = ChangePassword.call(user, %{password: "new_valid_password!"})
      assert %Ecto.Changeset{} = changeset
    end

    test "validates password length", %{user: user} do
      changeset = ChangePassword.call(user, %{password: "short"})
      assert errors_on(changeset).password
    end
  end
end
