defmodule Atlas.Communities.Comment.ReplyTest do
  use Atlas.DataCase, async: true

  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  alias Atlas.Communities.Comment.Reply

  setup do
    owner = user_fixture()
    community = community_fixture(owner)
    page = page_fixture(community, owner)
    comment = comment_fixture(page, owner, %{body: "Top-level comment"})

    %{page: page, comment: comment}
  end

  describe "call/4" do
    test "creates a reply to a comment", %{page: page, comment: parent} do
      replier = user_fixture()

      assert {:ok, reply} = Reply.call(page, parent, replier, %{body: "Nice point"})

      assert reply.body == "Nice point"
      assert reply.parent_id == parent.id
      assert reply.page_id == page.id
      assert reply.author_id == replier.id
    end

    test "rejects nested replies", %{page: page, comment: parent} do
      replier = user_fixture()
      {:ok, reply} = Reply.call(page, parent, replier, %{body: "First reply"})

      assert {:error, :no_nested_replies} =
               Reply.call(page, reply, replier, %{body: "Nested reply"})
    end

    test "returns error for empty body", %{page: page, comment: parent} do
      replier = user_fixture()

      assert {:error, changeset} = Reply.call(page, parent, replier, %{body: ""})
      assert errors_on(changeset).body
    end
  end
end
