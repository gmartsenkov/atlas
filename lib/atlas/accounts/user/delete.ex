defmodule Atlas.Accounts.User.Delete do
  @moduledoc false

  alias Atlas.Accounts

  def call(user, nickname_confirmation) do
    if nickname_confirmation == user.nickname do
      Accounts.delete_user(user)
    else
      {:error, :nickname_mismatch}
    end
  end
end
