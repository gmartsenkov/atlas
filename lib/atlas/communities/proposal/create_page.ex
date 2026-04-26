defmodule Atlas.Communities.Proposal.CreatePage do
  @moduledoc false

  alias Atlas.Authorization
  alias Atlas.Communities.Proposals

  def call(community, author, attrs) do
    if Authorization.can_propose?(community) do
      Proposals.create_page_proposal(community, author, attrs)
    else
      {:error, :suggestions_disabled}
    end
  end
end
