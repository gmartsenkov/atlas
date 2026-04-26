defmodule Atlas.Communities.Proposal.Update do
  @moduledoc false

  alias Atlas.Authorization
  alias Atlas.Communities.{Proposal, Proposals}

  def call(proposal, attrs, actor, community, is_moderator) do
    with :ok <- authorize(actor, proposal, community, is_moderator) do
      if Proposal.new_page_proposal?(proposal) do
        Proposals.update_page_proposal(proposal, attrs)
      else
        Proposals.update_proposal(proposal, attrs)
      end
    end
  end

  defp authorize(actor, proposal, community, is_moderator) do
    if Authorization.can_edit_proposal?(actor, proposal, community, is_moderator) do
      :ok
    else
      {:error, :unauthorized}
    end
  end
end
