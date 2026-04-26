defmodule Atlas.Accounts.User.RegisterTest do
  use Atlas.DataCase, async: true

  alias Atlas.Accounts.User.Register

  describe "call/1" do
    test "creates a user with valid attrs" do
      attrs = %{
        "email" => "test-#{System.unique_integer([:positive])}@example.com",
        "nickname" => "testuser",
        "terms_accepted" => "true"
      }

      assert {:ok, user} = Register.call(attrs)
      assert user.email == attrs["email"]
      assert user.nickname == attrs["nickname"]
    end

    test "returns error for invalid attrs" do
      assert {:error, changeset} = Register.call(%{"email" => "", "nickname" => ""})
      assert errors_on(changeset).email
    end

    test "returns error for duplicate email" do
      attrs = %{
        "email" => "dupe-#{System.unique_integer([:positive])}@example.com",
        "nickname" => "user1",
        "terms_accepted" => "true"
      }

      {:ok, _} = Register.call(attrs)

      assert {:error, changeset} =
               Register.call(%{attrs | "nickname" => "user2"})

      assert errors_on(changeset).email
    end
  end
end
