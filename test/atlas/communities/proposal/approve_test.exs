defmodule Atlas.Communities.Proposal.ApproveTest do
  use Atlas.DataCase, async: true

  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  alias Atlas.Communities.Proposal.Approve

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
    test "community owner can approve", %{
      owner: owner,
      community: community,
      page: page,
      proposal: proposal
    } do
      assert {:ok, %{proposal: approved}} =
               Approve.call(proposal, owner, community, page, false)

      assert approved.status == "approved"
      assert approved.reviewed_by_id == owner.id
    end

    test "moderator can approve", %{community: community, page: page, proposal: proposal} do
      moderator = user_fixture()

      assert {:ok, %{proposal: approved}} =
               Approve.call(proposal, moderator, community, page, true)

      assert approved.status == "approved"
    end

    test "random user cannot approve", %{community: community, page: page, proposal: proposal} do
      random = user_fixture()

      assert {:error, :unauthorized} =
               Approve.call(proposal, random, community, page, false)
    end

    test "cannot approve already reviewed proposal", %{
      owner: owner,
      community: community,
      page: page,
      proposal: proposal
    } do
      {:ok, _} = Approve.call(proposal, owner, community, page, false)
      proposal = Atlas.Repo.reload!(proposal)

      assert {:error, :not_pending} =
               Approve.call(proposal, owner, community, page, false)
    end
  end
end
