defmodule Atlas.Communities.Page.Update do
  @moduledoc false

  alias Atlas.Authorization
  alias Atlas.Communities.{PagesContext, Sections}

  def call(page, attrs, content, community, actor, is_moderator) do
    if Authorization.can_edit_page?(actor, page, community, is_moderator) do
      with {:ok, page} <- PagesContext.update_page(page, attrs),
           {:ok, sections} <- Sections.save_page_content(page, content) do
        {:ok, page, sections}
      end
    else
      {:error, :unauthorized}
    end
  end
end
