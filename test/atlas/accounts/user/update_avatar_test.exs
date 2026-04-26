defmodule Atlas.Accounts.User.UpdateAvatarTest do
  use Atlas.DataCase, async: true

  import Atlas.AccountsFixtures

  alias Atlas.Accounts.User.UpdateAvatar

  setup do
    %{user: user_fixture()}
  end

  describe "call/2" do
    test "sets avatar url", %{user: user} do
      assert {:ok, updated} = UpdateAvatar.call(user, %{avatar_url: "https://example.com/av.png"})
      assert updated.avatar_url == "https://example.com/av.png"
    end

    test "removes avatar url", %{user: user} do
      {:ok, with_avatar} = UpdateAvatar.call(user, %{avatar_url: "https://example.com/av.png"})

      assert {:ok, updated} = UpdateAvatar.call(with_avatar, %{avatar_url: nil})
      assert is_nil(updated.avatar_url)
    end
  end
end
