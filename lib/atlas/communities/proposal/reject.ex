defmodule Atlas.Communities.Proposal.Reject do
  @moduledoc false

  alias Atlas.Authorization
  alias Atlas.Communities.Proposals

  def call(proposal, reviewer, community, page, is_moderator) do
    with :ok <- authorize(reviewer, community, page, is_moderator) do
      Proposals.reject_proposal(proposal, reviewer)
    end
  end

  defp authorize(actor, community, page, is_moderator) do
    if Authorization.can_review_proposal?(actor, community, page, is_moderator) do
      :ok
    else
      {:error, :unauthorized}
    end
  end
end
