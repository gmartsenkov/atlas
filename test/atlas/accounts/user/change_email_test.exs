defmodule Atlas.Accounts.User.ChangeEmailTest do
  use Atlas.DataCase, async: true

  import Atlas.AccountsFixtures

  alias Atlas.Accounts.User.ChangeEmail

  setup do
    %{user: user_fixture()}
  end

  describe "call/3" do
    test "returns a changeset", %{user: user} do
      changeset = ChangeEmail.call(user, %{email: "new@example.com"})
      assert %Ecto.Changeset{} = changeset
    end

    test "validates email format", %{user: user} do
      changeset = ChangeEmail.call(user, %{email: "not-an-email"})
      assert errors_on(changeset).email
    end
  end
end
