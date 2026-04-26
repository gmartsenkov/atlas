defmodule Atlas.Communities.Comment.Create do
  @moduledoc false

  alias Atlas.Communities.CommentsContext

  def call(commentable, author, attrs) do
    CommentsContext.add_comment(commentable, author, attrs)
  end
end
