defmodule Atlas.Accounts.User.Register do
  @moduledoc false

  alias Atlas.Accounts

  def call(attrs) do
    Accounts.register_user(attrs)
  end
end
