defmodule Atlas.Communities.ProposalsTest do
  use Atlas.DataCase, async: true

  alias Atlas.Communities.Proposals
  alias Atlas.Communities.Sections

  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  setup do
    owner = user_fixture()
    community = community_fixture(owner)
    page = page_fixture(community, owner)
    [section | _] = Sections.list_sections(page.id)
    author = user_fixture()
    %{owner: owner, community: community, page: page, section: section, author: author}
  end

  describe "create_proposal/3" do
    test "creates a section edit proposal", %{section: section, author: author} do
      attrs = %{
        proposed_content: [paragraph_block("New content")]
      }

      assert {:ok, proposal} = Proposals.create_proposal(section, author, attrs)
      assert proposal.section_id == section.id
      assert proposal.author_id == author.id
      assert proposal.status == "pending"
    end
  end

  describe "create_page_proposal/3" do
    test "creates a new page proposal", %{community: community, author: author} do
      attrs = %{
        proposed_title: "New Page",
        proposed_slug: "new-page",
        proposed_content: [paragraph_block("Content")]
      }

      assert {:ok, proposal} = Proposals.create_page_proposal(community, author, attrs)
      assert proposal.community_id == community.id
      assert proposal.proposed_title == "New Page"
    end

    test "validates required fields", %{community: community, author: author} do
      assert {:error, changeset} = Proposals.create_page_proposal(community, author, %{})
      assert %{proposed_title: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "list_pending_proposals/1" do
    test "returns pending proposals for a page", %{section: section, author: author, page: page} do
      proposal_fixture(section, author)
      %{items: proposals} = Proposals.list_pending_proposals(page)
      assert length(proposals) == 1
      assert hd(proposals).status == "pending"
    end

    test "excludes non-pending proposals", %{
      section: section,
      author: author,
      page: page,
      owner: owner
    } do
      proposal = proposal_fixture(section, author)
      Proposals.reject_proposal(proposal, owner)

      assert %{items: []} = Proposals.list_pending_proposals(page)
    end
  end

  describe "count_pending_proposals/1" do
    test "counts pending proposals", %{section: section, author: author, page: page} do
      assert 0 == Proposals.count_pending_proposals(page)
      proposal_fixture(section, author)
      assert 1 == Proposals.count_pending_proposals(page)
    end
  end

  describe "list_community_proposals/2" do
    test "lists all proposals by default", %{
      community: community,
      section: section,
      author: author
    } do
      proposal_fixture(section, author)
      %{items: proposals} = Proposals.list_community_proposals(community)
      assert length(proposals) == 1
    end

    test "filters by status", %{
      community: community,
      section: section,
      author: author,
      owner: owner
    } do
      proposal = proposal_fixture(section, author)
      Proposals.reject_proposal(proposal, owner)

      assert %{items: []} = Proposals.list_community_proposals(community, "pending")
      assert length(Proposals.list_community_proposals(community, "rejected").items) == 1
    end

    test "includes page proposals", %{community: community, author: author} do
      page_proposal_fixture(community, author)
      %{items: proposals} = Proposals.list_community_proposals(community)
      assert length(proposals) == 1
    end
  end

  describe "count_community_pending_proposals/1" do
    test "counts pending across community", %{
      community: community,
      section: section,
      author: author
    } do
      assert 0 == Proposals.count_community_pending_proposals(community)
      proposal_fixture(section, author)
      assert 1 == Proposals.count_community_pending_proposals(community)
    end
  end

  describe "count_community_proposals_by_status/1" do
    test "returns counts grouped by status", %{
      community: community,
      section: section,
      author: author,
      owner: owner
    } do
      p1 = proposal_fixture(section, author)
      proposal_fixture(section, author)
      Proposals.reject_proposal(p1, owner)

      counts = Proposals.count_community_proposals_by_status(community)
      assert counts["pending"] == 1
      assert counts["rejected"] == 1
    end
  end

  describe "get_proposal/1" do
    test "returns proposal with preloads", %{section: section, author: author} do
      proposal = proposal_fixture(section, author)
      assert {:ok, found} = Proposals.get_proposal(proposal.id)
      assert found.author.id == author.id
      assert found.section.id == section.id
    end

    test "returns error for nonexistent id" do
      assert {:error, :not_found} = Proposals.get_proposal(-1)
    end
  end

  describe "approve_proposal/2 (section edit)" do
    test "approves and applies content to section", %{
      section: section,
      author: author,
      owner: owner
    } do
      content = [paragraph_block("Approved content")]
      proposal = proposal_fixture(section, author, %{proposed_content: content})

      assert {:ok, %{proposal: approved}} = Proposals.approve_proposal(proposal, owner)
      assert approved.status == "approved"
      assert approved.reviewed_by_id == owner.id
    end

    test "returns error for already reviewed proposal", %{
      section: section,
      author: author,
      owner: owner
    } do
      proposal = proposal_fixture(section, author)
      {:ok, %{proposal: approved}} = Proposals.approve_proposal(proposal, owner)

      assert {:error, :not_pending} = Proposals.approve_proposal(approved, owner)
    end
  end

  describe "approve_proposal/2 (new page)" do
    test "creates page and sections on approval", %{
      community: community,
      author: author,
      owner: owner
    } do
      proposal = page_proposal_fixture(community, author)

      assert {:ok, %{proposal: approved, page: page}} =
               Proposals.approve_proposal(proposal, owner)

      assert approved.status == "approved"
      assert page.title == "Proposed Page"
    end
  end

  describe "reject_proposal/2" do
    test "rejects a pending proposal", %{section: section, author: author, owner: owner} do
      proposal = proposal_fixture(section, author)
      assert {:ok, rejected} = Proposals.reject_proposal(proposal, owner)
      assert rejected.status == "rejected"
      assert rejected.reviewed_by_id == owner.id
    end

    test "returns error for non-pending proposal", %{
      section: section,
      author: author,
      owner: owner
    } do
      proposal = proposal_fixture(section, author)
      {:ok, rejected} = Proposals.reject_proposal(proposal, owner)

      assert {:error, :not_pending} = Proposals.reject_proposal(rejected, owner)
    end
  end
end
