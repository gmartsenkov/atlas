defmodule Atlas.Communities.SectionsTest do
  use Atlas.DataCase, async: true

  alias Atlas.Communities.Sections
  alias Atlas.Communities.Section

  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  setup do
    owner = user_fixture()
    community = community_fixture(owner)
    page = page_fixture(community, owner)
    %{owner: owner, community: community, page: page}
  end

  describe "list_sections/1" do
    test "returns sections ordered by sort_order", %{page: page} do
      # page_fixture creates one default section at sort_order 0
      sections = Sections.list_sections(page.id)
      assert length(sections) >= 1
      assert hd(sections).page_id == page.id
    end
  end

  describe "get_section/1" do
    test "returns section with proposals preloaded", %{page: page} do
      [section | _] = Sections.list_sections(page.id)
      assert {:ok, found} = Sections.get_section(section.id)
      assert found.id == section.id
      assert is_list(found.proposals)
    end

    test "returns error for nonexistent id" do
      assert {:error, :not_found} = Sections.get_section(-1)
    end
  end

  describe "save_page_content/2" do
    test "creates sections from blocks", %{page: page} do
      blocks = [
        heading_block("Introduction", 1),
        paragraph_block("Some text"),
        heading_block("Details", 2),
        paragraph_block("More text")
      ]

      assert {:ok, sections} = Sections.save_page_content(page, blocks)
      assert length(sections) == 2
    end

    test "updates existing sections in place", %{page: page} do
      blocks1 = [heading_block("V1", 1), paragraph_block("Original")]
      {:ok, [s1]} = Sections.save_page_content(page, blocks1)

      blocks2 = [heading_block("V2", 1), paragraph_block("Updated")]
      {:ok, [s2]} = Sections.save_page_content(page, blocks2)

      assert s1.id == s2.id
    end

    test "removes extra sections when content shrinks", %{page: page} do
      blocks = [
        heading_block("Section 1", 1),
        paragraph_block("Text 1"),
        heading_block("Section 2", 1),
        paragraph_block("Text 2")
      ]

      {:ok, sections} = Sections.save_page_content(page, blocks)
      assert length(sections) == 2

      blocks2 = [heading_block("Only One", 1), paragraph_block("Text")]
      {:ok, sections2} = Sections.save_page_content(page, blocks2)
      assert length(sections2) == 1
    end
  end

  describe "split_blocks_into_sections/1" do
    test "splits on h1 headings" do
      blocks = [
        heading_block("First", 1),
        paragraph_block("Body 1"),
        heading_block("Second", 1),
        paragraph_block("Body 2")
      ]

      sections = Sections.split_blocks_into_sections(blocks)
      assert length(sections) == 2
    end

    test "splits on h2 headings" do
      blocks = [
        heading_block("First", 2),
        paragraph_block("Body"),
        heading_block("Second", 2)
      ]

      sections = Sections.split_blocks_into_sections(blocks)
      assert length(sections) == 2
    end

    test "does not split on h3 headings" do
      blocks = [
        heading_block("Title", 1),
        %{
          "type" => "heading",
          "props" => %{"level" => 3},
          "content" => [%{"type" => "text", "text" => "Sub"}],
          "children" => []
        }
      ]

      sections = Sections.split_blocks_into_sections(blocks)
      assert length(sections) == 1
    end

    test "handles empty list" do
      assert [[]] = Sections.split_blocks_into_sections([])
    end

    test "keeps leading content without heading in first section" do
      blocks = [
        paragraph_block("No heading"),
        heading_block("Title", 1),
        paragraph_block("Body")
      ]

      sections = Sections.split_blocks_into_sections(blocks)
      assert length(sections) == 2
      [first, _second] = sections
      assert hd(first)["type"] == "paragraph"
    end
  end

  describe "merge_sections_content/1" do
    test "merges sorted sections content" do
      s1 = %Section{sort_order: 0, content: [paragraph_block("A")]}
      s2 = %Section{sort_order: 1, content: [paragraph_block("B")]}

      merged = Sections.merge_sections_content([s2, s1])
      assert length(merged) == 2
      assert hd(merged)["content"] |> hd() |> Map.get("text") == "A"
    end

    test "handles nil content" do
      s1 = %Section{sort_order: 0, content: nil}
      assert [] == Sections.merge_sections_content([s1])
    end
  end

  describe "title_from_blocks/1" do
    test "extracts title from h1 heading" do
      blocks = [heading_block("My Title", 1)]
      assert "My Title" == Sections.title_from_blocks(blocks)
    end

    test "extracts title from h2 heading" do
      blocks = [heading_block("Sub Title", 2)]
      assert "Sub Title" == Sections.title_from_blocks(blocks)
    end

    test "returns nil for non-heading first block" do
      blocks = [paragraph_block("Not a title")]
      assert nil == Sections.title_from_blocks(blocks)
    end

    test "returns nil for empty list" do
      assert nil == Sections.title_from_blocks([])
    end
  end

  describe "section_title/1" do
    test "returns heading text from section content" do
      section = %Section{content: [heading_block("Hello", 1)]}
      assert "Hello" == Sections.section_title(section)
    end

    test "returns Untitled for no heading" do
      section = %Section{content: [paragraph_block("no heading")]}
      assert "Untitled" == Sections.section_title(section)
    end

    test "returns Untitled for nil content" do
      assert "Untitled" == Sections.section_title(%Section{content: nil})
      assert "Untitled" == Sections.section_title(nil)
    end
  end

  describe "extract_headings/1" do
    test "extracts heading id, text, and level" do
      sections = [
        %Section{
          sort_order: 0,
          content: [
            heading_block("Title", 1, "h1"),
            heading_block("Subtitle", 2, "h2")
          ]
        }
      ]

      headings = Sections.extract_headings(sections)
      assert length(headings) == 2
      assert hd(headings) == %{id: "h1", text: "Title", level: 1}
    end

    test "skips headings without id" do
      sections = [
        %Section{sort_order: 0, content: [heading_block("No ID", 1)]}
      ]

      assert [] == Sections.extract_headings(sections)
    end
  end

  describe "slugify/1" do
    test "converts title to slug" do
      assert "hello-world" == Sections.slugify("Hello World")
    end

    test "removes special characters" do
      assert "hello-world" == Sections.slugify("Hello, World!")
    end

    test "collapses multiple hyphens" do
      assert "a-b" == Sections.slugify("a---b")
    end

    test "trims hyphens" do
      assert "hello" == Sections.slugify("-hello-")
    end

    test "handles non-binary" do
      assert "" == Sections.slugify(nil)
    end
  end
end
