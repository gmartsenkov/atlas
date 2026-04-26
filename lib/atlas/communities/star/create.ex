defmodule Atlas.Communities.Star.Create do
  @moduledoc false

  alias Atlas.Communities.Stars

  def call(user, page) do
    Stars.star_page(user, page)
  end
end
