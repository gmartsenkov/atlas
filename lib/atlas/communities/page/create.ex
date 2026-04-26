defmodule Atlas.Communities.Page.Create do
  @moduledoc false

  alias Atlas.Authorization
  alias Atlas.Communities.PagesContext

  def call(community, attrs, actor, is_moderator) do
    if Authorization.can_create_page?(actor, community, is_moderator) do
      PagesContext.create_page(attrs, actor)
    else
      {:error, :unauthorized}
    end
  end
end
