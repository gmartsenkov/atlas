defmodule Atlas.Communities do
  import Ecto.Query
  alias Atlas.Repo
  alias Atlas.Communities.{Community, CommunityMember, Page, Section, Proposal, ProposalComment}

  def list_communities do
    Community
    |> order_by(:name)
    |> with_member_count()
    |> Repo.all()
  end

  def search_communities(query) when is_binary(query) and query != "" do
    wildcard = "%#{query}%"

    Community
    |> where([c], ilike(c.name, ^wildcard) or ilike(c.description, ^wildcard))
    |> order_by(:name)
    |> with_member_count()
    |> Repo.all()
  end

  def search_communities(_), do: list_communities()

  defp with_member_count(query) do
    from c in query,
      left_join: m in CommunityMember,
      on: m.community_id == c.id,
      group_by: c.id,
      select_merge: %{member_count: count(m.id)}
  end

  def get_community_by_name!(name) do
    Community
    |> Repo.get_by!(name: name)
    |> Repo.preload([:owner, pages: from(p in Page, order_by: p.title)])
  end

  def create_community(attrs, owner) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:community, fn _changes ->
      %Community{}
      |> Community.changeset(Map.put(attrs, "owner_id", owner.id))
    end)
    |> Ecto.Multi.insert(:membership, fn %{community: community} ->
      %CommunityMember{}
      |> CommunityMember.changeset(%{user_id: owner.id, community_id: community.id})
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{community: community}} -> {:ok, community}
      {:error, :community, changeset, _} -> {:error, changeset}
      {:error, :membership, changeset, _} -> {:error, changeset}
    end
  end

  def change_community(community \\ %Community{}, attrs \\ %{}) do
    Community.changeset(community, attrs)
  end

  def update_community(%Community{} = community, attrs) do
    community
    |> Community.edit_changeset(attrs)
    |> Repo.update()
  end

  def change_community_edit(%Community{} = community, attrs \\ %{}) do
    Community.edit_changeset(community, attrs)
  end

  def join_community(user, community) do
    %CommunityMember{}
    |> CommunityMember.changeset(%{user_id: user.id, community_id: community.id})
    |> Repo.insert()
  end

  def leave_community(user, community) do
    Repo.delete_all(
      from m in CommunityMember,
        where: m.user_id == ^user.id and m.community_id == ^community.id
    )

    :ok
  end

  def member?(user, community) do
    Repo.exists?(
      from m in CommunityMember,
        where: m.user_id == ^user.id and m.community_id == ^community.id
    )
  end

  # --- Page functions ---

  def get_page_by_slugs!(community_name, page_slug) do
    from(p in Page,
      join: c in Community,
      on: c.id == p.community_id,
      where: c.name == ^community_name and p.slug == ^page_slug,
      preload: [:community, :owner, sections: ^from(s in Section, order_by: s.sort_order)]
    )
    |> Repo.one!()
  end

  def create_page(attrs, owner) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:page, fn _changes ->
      %Page{}
      |> Page.changeset(Map.put(attrs, "owner_id", owner.id))
    end)
    |> Ecto.Multi.insert(:section, fn %{page: page} ->
      %Section{}
      |> Section.changeset(%{
        content: [],
        sort_order: 0,
        page_id: page.id
      })
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{page: page}} -> {:ok, page}
      {:error, :page, changeset, _} -> {:error, changeset}
      {:error, :section, changeset, _} -> {:error, changeset}
    end
  end

  def update_page(page, attrs) do
    page
    |> Page.changeset(attrs)
    |> Repo.update()
  end

  def change_page(page \\ %Page{}, attrs \\ %{}) do
    Page.changeset(page, attrs)
  end

  # --- Section functions ---

  def list_sections(page_id) do
    from(s in Section, where: s.page_id == ^page_id, order_by: s.sort_order)
    |> Repo.all()
  end

  def get_section!(id) do
    Section
    |> Repo.get!(id)
    |> Repo.preload(proposals: [:author])
  end

  def create_section(page, attrs) do
    %Section{}
    |> Section.changeset(Map.put(attrs, :page_id, page.id))
    |> Repo.insert()
  end

  def update_section(section, attrs) do
    section
    |> Section.changeset(attrs)
    |> Repo.update()
  end

  def delete_section(section) do
    Repo.delete(section)
  end

  def save_page_content(page, blocks) when is_list(blocks) do
    splits = split_blocks_into_sections(blocks)
    existing = list_sections(page.id)

    multi =
      Ecto.Multi.new()
      |> then(fn multi ->
        splits
        |> Enum.with_index()
        |> Enum.reduce(multi, fn {content, idx}, multi ->
          case Enum.at(existing, idx) do
            nil ->
              Ecto.Multi.insert(multi, {:section, idx}, fn _changes ->
                %Section{}
                |> Section.changeset(%{
                  content: content,
                  sort_order: idx,
                  page_id: page.id
                })
              end)

            section ->
              Ecto.Multi.update(multi, {:section, idx}, fn _changes ->
                section
                |> Section.changeset(%{content: content, sort_order: idx})
              end)
          end
        end)
      end)
      |> then(fn multi ->
        existing
        |> Enum.drop(length(splits))
        |> Enum.reduce(multi, fn section, multi ->
          has_pending =
            from(p in Proposal, where: p.section_id == ^section.id and p.status == "pending")
            |> Repo.exists?()

          if has_pending do
            multi
          else
            Ecto.Multi.delete(multi, {:delete_section, section.id}, section)
          end
        end)
      end)

    case Repo.transaction(multi) do
      {:ok, _results} ->
        {:ok, list_sections(page.id)}

      {:error, _key, reason, _changes} ->
        {:error, reason}
    end
  end

  def split_blocks_into_sections(blocks) when is_list(blocks) do
    {sections, current_blocks} =
      Enum.reduce(blocks, {[], []}, fn block, {sections, acc} ->
        if block["type"] == "heading" and get_in(block, ["props", "level"]) in [1, 2] do
          if acc == [] do
            {sections, [block]}
          else
            {sections ++ [Enum.reverse(acc)], [block]}
          end
        else
          {sections, [block | acc]}
        end
      end)

    sections ++ [Enum.reverse(current_blocks)]
  end

  def merge_sections_content(sections) when is_list(sections) do
    sections
    |> Enum.sort_by(& &1.sort_order)
    |> Enum.flat_map(&(&1.content || []))
  end

  def title_from_blocks([%{"type" => "heading", "props" => %{"level" => level}} = block | _])
      when level in [1, 2] do
    get_in(block, ["content", Access.at(0), "text"])
  end

  def title_from_blocks(_), do: nil

  def section_title(%Section{content: content}) when is_list(content) do
    title_from_blocks(content) || "Untitled"
  end

  def section_title(_), do: "Untitled"

  # --- Full-text search ---

  def search_community_content(community, query) when is_binary(query) and query != "" do
    from(s in Section,
      join: p in Page,
      on: p.id == s.page_id,
      where: p.community_id == ^community.id,
      where:
        fragment(
          "? @@ plainto_tsquery('english', ?)",
          s.search_text,
          ^query
        ),
      order_by: [
        desc:
          fragment(
            "ts_rank(?, plainto_tsquery('english', ?))",
            s.search_text,
            ^query
          )
      ],
      select: %{
        section_id: s.id,
        page_id: p.id,
        page_title: p.title,
        page_slug: p.slug,
        snippet:
          fragment(
            """
            ts_headline('english',
              coalesce((
                SELECT string_agg(elem, ' ')
                FROM (
                  SELECT jsonb_array_elements(jsonb_array_elements(?) -> 'content') ->> 'text' AS elem
                ) sub
                WHERE elem IS NOT NULL
              ), ''),
              plainto_tsquery('english', ?),
              'MaxWords=30, MinWords=15, StartSel=<mark>, StopSel=</mark>')
            """,
            s.content,
            ^query
          )
      }
    )
    |> Repo.all()
  end

  def search_community_content(_community, _query), do: []

  # --- Proposal functions ---

  def create_proposal(section, author, attrs) do
    %Proposal{}
    |> Proposal.changeset(
      attrs
      |> Map.put(:section_id, section.id)
      |> Map.put(:author_id, author.id)
    )
    |> Repo.insert()
  end

  def list_pending_proposals(page) do
    from(pr in Proposal,
      join: s in Section,
      on: s.id == pr.section_id,
      where: s.page_id == ^page.id and pr.status == "pending",
      preload: [:author, :section],
      order_by: [desc: pr.inserted_at]
    )
    |> Repo.all()
  end

  def count_pending_proposals(page) do
    from(pr in Proposal,
      join: s in Section,
      on: s.id == pr.section_id,
      where: s.page_id == ^page.id and pr.status == "pending",
      select: count(pr.id)
    )
    |> Repo.one()
  end

  def list_community_proposals(community, status \\ "all") do
    query =
      from(pr in Proposal,
        join: s in Section,
        on: s.id == pr.section_id,
        join: p in Page,
        on: p.id == s.page_id,
        where: p.community_id == ^community.id,
        preload: [:author, section: :page],
        order_by: [desc: pr.inserted_at]
      )

    query =
      if status != "all",
        do: where(query, [pr], pr.status == ^status),
        else: query

    Repo.all(query)
  end

  def count_community_pending_proposals(community) do
    from(pr in Proposal,
      join: s in Section,
      on: s.id == pr.section_id,
      join: p in Page,
      on: p.id == s.page_id,
      where: p.community_id == ^community.id and pr.status == "pending",
      select: count(pr.id)
    )
    |> Repo.one()
  end

  def count_community_proposals_by_status(community) do
    from(pr in Proposal,
      join: s in Section,
      on: s.id == pr.section_id,
      join: p in Page,
      on: p.id == s.page_id,
      where: p.community_id == ^community.id,
      group_by: pr.status,
      select: {pr.status, count(pr.id)}
    )
    |> Repo.all()
    |> Map.new()
  end

  def get_proposal!(id) do
    Proposal
    |> Repo.get!(id)
    |> Repo.preload([:section, :author, :reviewed_by, comments: [:author]])
  end

  def approve_proposal(proposal, reviewer) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:proposal, fn _changes ->
      Proposal.review_changeset(proposal, %{
        status: "approved",
        reviewed_by_id: reviewer.id,
        reviewed_at: DateTime.utc_now() |> DateTime.truncate(:second)
      })
    end)
    |> Ecto.Multi.run(:sections, fn repo, %{proposal: proposal} ->
      section = repo.get!(Section, proposal.section_id)

      if proposal.proposed_content == [] do
        {:ok, [section]}
      else
        splits = split_blocks_into_sections(proposal.proposed_content)
        [first_content | rest] = splits
        extra_count = length(rest)

        # Shift subsequent sections to make room for new ones
        if extra_count > 0 do
          from(s in Section,
            where: s.page_id == ^section.page_id and s.sort_order > ^section.sort_order
          )
          |> repo.update_all(inc: [sort_order: extra_count])
        end

        # Update the target section with the first split
        {:ok, updated} =
          section
          |> Section.changeset(%{content: first_content})
          |> repo.update()

        # Insert additional sections
        new_sections =
          rest
          |> Enum.with_index(1)
          |> Enum.map(fn {split_content, idx} ->
            {:ok, new_section} =
              %Section{}
              |> Section.changeset(%{
                content: split_content,
                sort_order: section.sort_order + idx,
                page_id: section.page_id
              })
              |> repo.insert()

            new_section
          end)

        {:ok, [updated | new_sections]}
      end
    end)
    |> Repo.transaction()
  end

  def reject_proposal(proposal, reviewer) do
    proposal
    |> Proposal.review_changeset(%{
      status: "rejected",
      reviewed_by_id: reviewer.id,
      reviewed_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
    |> Repo.update()
  end

  def add_proposal_comment(proposal, author, attrs) do
    %ProposalComment{}
    |> ProposalComment.changeset(
      attrs
      |> Map.put(:proposal_id, proposal.id)
      |> Map.put(:author_id, author.id)
    )
    |> Repo.insert()
  end
end
