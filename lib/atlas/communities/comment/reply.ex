defmodule Atlas.Communities.Comment.Reply do
  @moduledoc false

  alias Atlas.Communities.CommentsContext

  def call(commentable, parent, author, attrs) do
    CommentsContext.reply_to_comment(commentable, parent, author, attrs)
  end
end
