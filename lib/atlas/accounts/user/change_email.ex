defmodule Atlas.Accounts.User.ChangeEmail do
  @moduledoc false

  alias Atlas.Accounts

  def call(user, attrs, opts \\ []) do
    Accounts.change_user_email(user, attrs, opts)
  end
end
