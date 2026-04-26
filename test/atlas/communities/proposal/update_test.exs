defmodule Atlas.Communities.Proposal.UpdateTest do
  use Atlas.DataCase, async: true

  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  alias Atlas.Communities.Proposal.Update
  alias Atlas.Communities.Proposals

  setup do
    owner = user_fixture()
    community = community_fixture(owner, %{"suggestions_enabled" => true})
    page = page_fixture(community, owner)
    section = section_fixture(page, %{content: [paragraph_block("Original")], sort_order: 0})
    author = user_fixture()
    proposal = proposal_fixture(section, author)

    %{owner: owner, community: community, author: author, proposal: proposal}
  end

  describe "call/5" do
    test "author can update their proposal", %{
      author: author,
      community: community,
      proposal: proposal
    } do
      attrs = %{proposed_content: [paragraph_block("Updated")]}

      assert {:ok, updated} = Update.call(proposal, attrs, author, community, false)
      assert updated.proposed_content == [paragraph_block("Updated")]
    end

    test "community owner can update any proposal", %{
      owner: owner,
      community: community,
      proposal: proposal
    } do
      attrs = %{proposed_content: [paragraph_block("Owner edit")]}

      assert {:ok, _updated} = Update.call(proposal, attrs, owner, community, false)
    end

    test "moderator can update any proposal", %{community: community, proposal: proposal} do
      moderator = user_fixture()
      attrs = %{proposed_content: [paragraph_block("Mod edit")]}

      assert {:ok, _updated} = Update.call(proposal, attrs, moderator, community, true)
    end

    test "random user cannot update proposal", %{community: community, proposal: proposal} do
      random = user_fixture()

      assert {:error, :unauthorized} =
               Update.call(proposal, %{proposed_content: []}, random, community, false)
    end

    test "returns not_pending for already reviewed proposal", %{
      owner: owner,
      community: community,
      proposal: proposal
    } do
      # Approve the proposal first
      Proposals.approve_proposal(proposal, owner)
      proposal = Repo.reload!(proposal)

      assert {:error, :not_pending} =
               Update.call(proposal, %{proposed_content: []}, owner, community, false)
    end
  end
end
