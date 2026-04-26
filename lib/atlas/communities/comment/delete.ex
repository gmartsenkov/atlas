defmodule Atlas.Communities.Comment.Delete do
  @moduledoc false

  alias Atlas.Authorization
  alias Atlas.Communities.CommentsContext

  def call(comment, commentable, actor, is_moderator) do
    if Authorization.can_delete_comment?(actor, comment, commentable, is_moderator) do
      CommentsContext.delete_comment(comment)
    else
      {:error, :unauthorized}
    end
  end
end
