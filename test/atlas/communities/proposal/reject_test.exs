defmodule Atlas.Communities.Proposal.RejectTest do
  use Atlas.DataCase, async: true

  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  alias Atlas.Communities.Proposal.Reject

  setup do
    owner = user_fixture()
    community = community_fixture(owner, %{"suggestions_enabled" => true})
    page = page_fixture(community, owner)
    section = section_fixture(page, %{content: [paragraph_block("Original")], sort_order: 0})
    author = user_fixture()
    proposal = proposal_fixture(section, author)

    %{owner: owner, community: community, page: page, proposal: proposal}
  end

  describe "call/5" do
    test "community owner can reject", %{
      owner: owner,
      community: community,
      page: page,
      proposal: proposal
    } do
      assert {:ok, rejected} = Reject.call(proposal, owner, community, page, false)
      assert rejected.status == "rejected"
      assert rejected.reviewed_by_id == owner.id
    end

    test "moderator can reject", %{community: community, page: page, proposal: proposal} do
      moderator = user_fixture()

      assert {:ok, rejected} = Reject.call(proposal, moderator, community, page, true)
      assert rejected.status == "rejected"
    end

    test "random user cannot reject", %{community: community, page: page, proposal: proposal} do
      random = user_fixture()

      assert {:error, :unauthorized} =
               Reject.call(proposal, random, community, page, false)
    end

    test "cannot reject already reviewed proposal", %{
      owner: owner,
      community: community,
      page: page,
      proposal: proposal
    } do
      {:ok, _} = Reject.call(proposal, owner, community, page, false)
      proposal = Atlas.Repo.reload!(proposal)

      assert {:error, :not_pending} =
               Reject.call(proposal, owner, community, page, false)
    end
  end
end
