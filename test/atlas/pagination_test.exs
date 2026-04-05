defmodule Atlas.PaginationTest do
  use Atlas.DataCase, async: true

  import Ecto.Query

  alias Atlas.Communities.PageComment
  alias Atlas.Pagination

  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  setup do
    owner = user_fixture()
    community = community_fixture(owner)
    page = page_fixture(community, owner)

    for i <- 1..5 do
      page_comment_fixture(page, owner, %{body: "Comment #{i}"})
    end

    %{page: page}
  end

  defp scoped_query(page) do
    from(c in PageComment, where: c.page_id == ^page.id, order_by: c.inserted_at)
  end

  describe "paginate/2" do
    test "returns first page with defaults", %{page: page} do
      result = Pagination.paginate(scoped_query(page))
      assert length(result.items) == 5
      assert result.total == 5
      assert result.offset == 0
      assert result.limit == 20
      assert result.has_more == false
    end

    test "respects limit option", %{page: page} do
      result = Pagination.paginate(scoped_query(page), limit: 2)
      assert length(result.items) == 2
      assert result.total == 5
      assert result.has_more == true
    end

    test "respects offset option", %{page: page} do
      result = Pagination.paginate(scoped_query(page), limit: 2, offset: 3)
      assert length(result.items) == 2
      assert result.total == 5
      assert result.offset == 3
      assert result.has_more == false
    end

    test "has_more is true when more items exist", %{page: page} do
      result = Pagination.paginate(scoped_query(page), limit: 3, offset: 0)
      assert result.has_more == true
    end

    test "has_more is false on last page", %{page: page} do
      result = Pagination.paginate(scoped_query(page), limit: 3, offset: 3)
      assert result.has_more == false
    end

    test "returns empty items when offset exceeds total", %{page: page} do
      result = Pagination.paginate(scoped_query(page), limit: 2, offset: 100)
      assert result.items == []
      assert result.total == 5
      assert result.has_more == false
    end
  end
end
