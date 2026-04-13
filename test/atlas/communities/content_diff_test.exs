defmodule Atlas.Communities.ContentDiffTest do
  use ExUnit.Case, async: true

  alias Atlas.Communities.ContentDiff

  defp text_block(text, type \\ "paragraph") do
    %{
      "id" => "block-#{System.unique_integer([:positive])}",
      "type" => type,
      "props" => %{},
      "content" => [%{"type" => "text", "text" => text}],
      "children" => []
    }
  end

  defp heading_block(text, level \\ 1) do
    %{
      "id" => "block-#{System.unique_integer([:positive])}",
      "type" => "heading",
      "props" => %{"level" => level},
      "content" => [%{"type" => "text", "text" => text}],
      "children" => []
    }
  end

  defp image_block(url) do
    %{
      "id" => "block-#{System.unique_integer([:positive])}",
      "type" => "image",
      "props" => %{"url" => url},
      "content" => [],
      "children" => []
    }
  end

  describe "diff_blocks/2" do
    test "identical blocks return all :eq" do
      blocks = [text_block("Hello"), text_block("World")]
      assert [{:eq, _}, {:eq, _}] = ContentDiff.diff_blocks(blocks, blocks)
    end

    test "empty old returns all :ins" do
      blocks = [text_block("Hello")]
      assert [{:ins, _}] = ContentDiff.diff_blocks([], blocks)
    end

    test "empty new returns all :del" do
      blocks = [text_block("Hello")]
      assert [{:del, _}] = ContentDiff.diff_blocks(blocks, [])
    end

    test "both empty returns empty list" do
      assert [] = ContentDiff.diff_blocks([], [])
    end

    test "nil inputs treated as empty" do
      assert [] = ContentDiff.diff_blocks(nil, nil)
      assert [{:ins, _}] = ContentDiff.diff_blocks(nil, [text_block("Hello")])
      assert [{:del, _}] = ContentDiff.diff_blocks([text_block("Hello")], nil)
    end

    test "added block at end" do
      old = [text_block("Hello")]
      new_block = text_block("World")
      new = [text_block("Hello"), new_block]

      result = ContentDiff.diff_blocks(old, new)
      assert [{:eq, _}, {:ins, ^new_block}] = result
    end

    test "removed block" do
      removed = text_block("Goodbye")
      old = [text_block("Hello"), removed]
      new = [text_block("Hello")]

      result = ContentDiff.diff_blocks(old, new)
      assert [{:eq, _}, {:del, ^removed}] = result
    end

    test "modified paragraph collapses to :mod" do
      old = [text_block("Hello world")]
      new = [text_block("Hello earth")]

      assert [{:mod, old_block, new_block}] = ContentDiff.diff_blocks(old, new)
      assert old_block["content"] == [%{"type" => "text", "text" => "Hello world"}]
      assert new_block["content"] == [%{"type" => "text", "text" => "Hello earth"}]
    end

    test "modified heading collapses to :mod when same type" do
      old = [heading_block("Old Title")]
      new = [heading_block("New Title")]

      assert [{:mod, _, _}] = ContentDiff.diff_blocks(old, new)
    end

    test "different types do not collapse to :mod" do
      old = [text_block("Hello")]
      new = [heading_block("Hello")]

      result = ContentDiff.diff_blocks(old, new)
      assert [{:del, _}, {:ins, _}] = result
    end

    test "image blocks do not collapse to :mod" do
      old = [image_block("http://example.com/a.jpg")]
      new = [image_block("http://example.com/b.jpg")]

      result = ContentDiff.diff_blocks(old, new)
      assert [{:del, _}, {:ins, _}] = result
    end

    test "mixed operations" do
      old = [text_block("Keep"), text_block("Change me"), text_block("Remove")]
      new = [text_block("Keep"), text_block("Changed"), text_block("Added")]

      result = ContentDiff.diff_blocks(old, new)

      # Both changed blocks share type "paragraph", so both collapse to :mod
      assert [
               {:eq, _},
               {:mod, _, _},
               {:mod, _, _}
             ] = result
    end

    test "mixed operations with type mismatch" do
      old = [text_block("Keep"), text_block("Remove"), heading_block("Old heading")]
      new = [text_block("Keep"), text_block("Added")]

      result = ContentDiff.diff_blocks(old, new)

      assert [
               {:eq, _},
               {:mod, _, _},
               {:del, _}
             ] = result
    end
  end

  describe "diff_words/2" do
    test "identical text returns all :eq" do
      block = text_block("Hello world")
      result = ContentDiff.diff_words(block, block)
      assert [{:eq, "Hello"}, {:eq, " "}, {:eq, "world"}] = result
    end

    test "changed word" do
      old = text_block("Hello world")
      new = text_block("Hello earth")
      result = ContentDiff.diff_words(old, new)

      assert [{:eq, "Hello"}, {:eq, " "}, {:del, "world"}, {:ins, "earth"}] = result
    end

    test "added words" do
      old = text_block("Hello")
      new = text_block("Hello world")
      result = ContentDiff.diff_words(old, new)

      assert [{:eq, "Hello"}, {:ins, " "}, {:ins, "world"}] = result
    end

    test "removed words" do
      old = text_block("Hello beautiful world")
      new = text_block("Hello world")
      result = ContentDiff.diff_words(old, new)

      assert [{:eq, "Hello"}, {:eq, " "}, {:del, "beautiful"}, {:del, " "}, {:eq, "world"}] =
               result
    end

    test "empty blocks" do
      old = %{"content" => []}
      new = %{"content" => []}
      assert [] = ContentDiff.diff_words(old, new)
    end
  end

  describe "extract_text/1" do
    test "extracts from simple text items" do
      block = text_block("Hello world")
      assert "Hello world" = ContentDiff.extract_text(block)
    end

    test "concatenates multiple text items" do
      block = %{
        "type" => "paragraph",
        "content" => [
          %{"type" => "text", "text" => "Hello "},
          %{"type" => "text", "text" => "world"}
        ]
      }

      assert "Hello world" = ContentDiff.extract_text(block)
    end

    test "extracts text from links" do
      block = %{
        "type" => "paragraph",
        "content" => [
          %{"type" => "text", "text" => "Visit "},
          %{
            "type" => "link",
            "href" => "http://example.com",
            "content" => [%{"type" => "text", "text" => "here"}]
          }
        ]
      }

      assert "Visit here" = ContentDiff.extract_text(block)
    end

    test "handles nil and missing content" do
      assert "" = ContentDiff.extract_text(%{})
      assert "" = ContentDiff.extract_text(nil)
    end
  end
end
