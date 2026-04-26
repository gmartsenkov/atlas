defmodule Atlas.Accounts.User.UpdateAvatar do
  @moduledoc false

  alias Atlas.Accounts

  def call(user, attrs) do
    Accounts.update_user_avatar(user, attrs)
  end
end
