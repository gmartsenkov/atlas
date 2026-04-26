defmodule Atlas.Communities.Proposal.Create do
  @moduledoc false

  alias Atlas.Authorization
  alias Atlas.Communities.Proposals

  def call(section, community, author, attrs) do
    if Authorization.can_propose?(community) do
      Proposals.create_proposal(section, author, attrs)
    else
      {:error, :suggestions_disabled}
    end
  end
end
