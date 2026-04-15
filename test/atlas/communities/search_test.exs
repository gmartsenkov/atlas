defmodule Atlas.Communities.SearchTest do
  use Atlas.DataCase, async: true

  alias Atlas.Communities.Search

  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  setup do
    owner = user_fixture()
    community = community_fixture(owner)
    page = page_fixture(community, owner)
    %{owner: owner, community: community, page: page}
  end

  describe "search_community_content/2" do
    test "returns empty list for blank query", %{community: community} do
      assert [] == Search.search_community_content(community, "")
      assert [] == Search.search_community_content(community, "   ")
    end

    test "returns empty list for non-binary query", %{community: community} do
      assert [] == Search.search_community_content(community, nil)
    end

    test "returns results matching section content", %{community: community, page: page} do
      blocks = [
        paragraph_block("Elixir is a functional programming language")
      ]

      Atlas.Communities.Sections.save_page_content(page, blocks)

      results = Search.search_community_content(community, "Elixir")
      assert results != []
      assert hd(results).page_id == page.id
    end

    test "returns empty for non-matching query", %{community: community, page: page} do
      blocks = [paragraph_block("Elixir programming")]
      Atlas.Communities.Sections.save_page_content(page, blocks)

      assert [] == Search.search_community_content(community, "xyznonexistent")
    end
  end
end
