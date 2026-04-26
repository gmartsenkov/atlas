defmodule Atlas.Communities.Proposal.CreatePageTest do
  use Atlas.DataCase, async: true

  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  alias Atlas.Communities.Proposal.CreatePage

  setup do
    owner = user_fixture()
    community = community_fixture(owner, %{"suggestions_enabled" => true})

    %{owner: owner, community: community}
  end

  describe "call/3" do
    test "creates a new page proposal", %{community: community} do
      author = user_fixture()

      attrs = %{
        proposed_title: "New Page",
        proposed_slug: "new-page",
        proposed_content: [paragraph_block("Content")]
      }

      assert {:ok, proposal} = CreatePage.call(community, author, attrs)
      assert proposal.community_id == community.id
      assert proposal.author_id == author.id
      assert proposal.proposed_title == "New Page"
      assert proposal.status == "pending"
    end

    test "rejects when suggestions are disabled" do
      owner = user_fixture()
      community = community_fixture(owner, %{"suggestions_enabled" => false})
      author = user_fixture()

      assert {:error, :suggestions_disabled} =
               CreatePage.call(community, author, %{
                 proposed_title: "Nope",
                 proposed_slug: "nope",
                 proposed_content: []
               })
    end

    test "returns error for missing title", %{community: community} do
      author = user_fixture()

      assert {:error, changeset} =
               CreatePage.call(community, author, %{
                 proposed_slug: "no-title",
                 proposed_content: []
               })

      assert errors_on(changeset).proposed_title
    end
  end
end
