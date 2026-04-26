defmodule Atlas.Communities.Proposal.CreateTest do
  use Atlas.DataCase, async: true

  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  alias Atlas.Communities.Proposal.Create

  setup do
    owner = user_fixture()
    community = community_fixture(owner, %{"suggestions_enabled" => true})
    page = page_fixture(community, owner)
    section = section_fixture(page, %{content: [paragraph_block("Hello")], sort_order: 0})

    %{owner: owner, community: community, section: section}
  end

  describe "call/4" do
    test "creates a section proposal", %{community: community, section: section} do
      author = user_fixture()
      attrs = %{proposed_content: [paragraph_block("Updated")]}

      assert {:ok, proposal} = Create.call(section, community, author, attrs)
      assert proposal.section_id == section.id
      assert proposal.author_id == author.id
      assert proposal.status == "pending"
    end

    test "rejects when suggestions are disabled", %{section: section} do
      owner = user_fixture()
      community = community_fixture(owner, %{"suggestions_enabled" => false})
      author = user_fixture()

      assert {:error, :suggestions_disabled} =
               Create.call(section, community, author, %{proposed_content: []})
    end
  end
end
