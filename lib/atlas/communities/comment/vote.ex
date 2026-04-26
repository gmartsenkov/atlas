defmodule Atlas.Communities.Comment.Vote do
  @moduledoc false

  alias Atlas.Communities.CommentsContext

  def cast(user, comment_id, value) when value in [1, -1] do
    CommentsContext.vote_comment(user, comment_id, value)
  end

  def remove(user, comment_id) do
    CommentsContext.unvote_comment(user, comment_id)
  end
end
