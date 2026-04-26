defmodule Atlas.Communities.Moderation.UnrestrictUser do
  @moduledoc false

  alias Atlas.Communities.{Moderation, RestrictionsContext}

  def call(restriction_id, community, actor) do
    with :ok <- Moderation.authorize_moderator(actor, community),
         {:ok, restriction} <- RestrictionsContext.get_restriction(restriction_id) do
      RestrictionsContext.delete_restriction(restriction)
    end
  end
end
