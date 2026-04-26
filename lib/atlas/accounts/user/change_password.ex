defmodule Atlas.Accounts.User.ChangePassword do
  @moduledoc false

  alias Atlas.Accounts

  def call(user, attrs, opts \\ []) do
    Accounts.change_user_password(user, attrs, opts)
  end
end
