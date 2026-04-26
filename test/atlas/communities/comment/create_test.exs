defmodule Atlas.Communities.Comment.CreateTest do
  use Atlas.DataCase, async: true

  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  alias Atlas.Communities.Comment.Create

  setup do
    owner = user_fixture()
    community = community_fixture(owner)
    page = page_fixture(community, owner)

    %{owner: owner, community: community, page: page}
  end

  describe "call/3" do
    test "creates a comment on a page", %{page: page} do
      author = user_fixture()

      assert {:ok, comment} = Create.call(page, author, %{body: "Hello world"})

      assert comment.body == "Hello world"
      assert comment.author_id == author.id
      assert comment.page_id == page.id
      assert is_nil(comment.parent_id)
    end

    test "creates a comment on a proposal", %{page: page} do
      author = user_fixture()
      section = section_fixture(page, %{content: [], sort_order: 0})
      proposal = proposal_fixture(section, author)

      assert {:ok, comment} = Create.call(proposal, author, %{body: "Looks good"})

      assert comment.proposal_id == proposal.id
    end

    test "returns error for empty body", %{page: page} do
      author = user_fixture()

      assert {:error, changeset} = Create.call(page, author, %{body: ""})
      assert errors_on(changeset).body
    end
  end
end
