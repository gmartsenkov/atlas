defmodule Atlas.Communities.Star.Delete do
  @moduledoc false

  alias Atlas.Communities.Stars

  def call(user, page) do
    Stars.unstar_page(user, page)
  end
end
