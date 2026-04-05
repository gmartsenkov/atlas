defmodule Atlas.CommunitiesFixtures do
  @moduledoc """
  Test helpers for creating communities context entities.
  """

  alias Atlas.Communities
  alias Atlas.Repo

  def unique_community_name, do: "community#{System.unique_integer([:positive])}"

  def community_fixture(owner, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        "name" => unique_community_name(),
        "description" => "A test community"
      })

    {:ok, community} = Communities.create_community(attrs, owner)
    community
  end

  def page_fixture(community, owner, attrs \\ %{}) do
    slug = "page-#{System.unique_integer([:positive])}"

    attrs =
      Enum.into(attrs, %{
        "title" => "Test Page",
        "slug" => slug,
        "community_id" => community.id
      })

    {:ok, page} = Communities.create_page(attrs, owner)
    page
  end

  def section_fixture(page, attrs \\ %{}) do
    attrs =
      Map.merge(
        %{content: [], sort_order: 0, page_id: page.id},
        attrs
      )

    %Communities.Section{}
    |> Communities.Section.changeset(attrs)
    |> Repo.insert!()
  end

  def collection_fixture(community, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        "name" => "collection#{System.unique_integer([:positive])}"
      })

    {:ok, collection} = Communities.create_collection(community, attrs)
    collection
  end

  def proposal_fixture(section, author, attrs \\ %{}) do
    attrs =
      Map.merge(
        %{
          proposed_content: [
            %{
              "type" => "paragraph",
              "content" => [%{"type" => "text", "text" => "Proposed change"}],
              "children" => []
            }
          ]
        },
        attrs
      )

    {:ok, proposal} = Communities.create_proposal(section, author, attrs)
    proposal
  end

  def page_proposal_fixture(community, author, attrs \\ %{}) do
    slug = "proposed-page-#{System.unique_integer([:positive])}"

    attrs =
      Map.merge(
        %{
          proposed_title: "Proposed Page",
          proposed_slug: slug,
          proposed_content: [
            %{
              "type" => "paragraph",
              "content" => [%{"type" => "text", "text" => "New page content"}],
              "children" => []
            }
          ]
        },
        attrs
      )

    {:ok, proposal} = Communities.create_page_proposal(community, author, attrs)
    proposal
  end

  def page_comment_fixture(page, author, attrs \\ %{}) do
    attrs =
      Map.merge(
        %{body: "A test comment"},
        attrs
      )

    {:ok, comment} = Communities.add_page_comment(page, author, attrs)
    comment
  end

  def heading_block(text, level \\ 1, id \\ nil) do
    block = %{
      "type" => "heading",
      "props" => %{"level" => level},
      "content" => [%{"type" => "text", "text" => text}],
      "children" => []
    }

    if id, do: Map.put(block, "id", id), else: block
  end

  def paragraph_block(text) do
    %{
      "type" => "paragraph",
      "content" => [%{"type" => "text", "text" => text}],
      "children" => []
    }
  end
end
