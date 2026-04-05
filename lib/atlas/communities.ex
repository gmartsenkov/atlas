defmodule Atlas.Communities do
  @moduledoc false
  import Ecto.Query

  alias Atlas.Communities.{
    Collection,
    Community,
    CommunityMember,
    Page,
    PageComment,
    PageStar,
    Proposal,
    ProposalComment,
    Section
  }

  alias Atlas.Repo

  def list_communities do
    Community
    |> order_by(:name)
    |> with_member_count()
    |> Repo.all()
  end

  def search_communities(query) when is_binary(query) and query != "" do
    escaped = query |> String.replace("\\", "\\\\") |> String.replace("%", "\\%") |> String.replace("_", "\\_")
    wildcard = "%#{escaped}%"

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

  def get_community_by_name(name) do
    case Repo.get_by(Community, name: name) do
      nil ->
        {:error, :not_found}

      community ->
        {:ok,
         Repo.preload(community, [
           :owner,
           pages: from(p in Page, order_by: [p.sort_order, p.title]),
           collections: from(c in Collection, order_by: [c.sort_order, c.name])
         ])}
    end
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
    if community.owner_id == user.id do
      {:error, :owner_cannot_leave}
    else
      Repo.delete_all(
        from m in CommunityMember,
          where: m.user_id == ^user.id and m.community_id == ^community.id
      )

      :ok
    end
  end

  def member?(user, community) do
    Repo.exists?(
      from m in CommunityMember,
        where: m.user_id == ^user.id and m.community_id == ^community.id
    )
  end

  # --- Page star functions ---

  def star_page(user, page) do
    %PageStar{}
    |> PageStar.changeset(%{user_id: user.id, page_id: page.id})
    |> Repo.insert()
  end

  def unstar_page(user, page) do
    Repo.delete_all(
      from s in PageStar,
        where: s.user_id == ^user.id and s.page_id == ^page.id
    )

    :ok
  end

  def page_starred?(user, page) do
    Repo.exists?(
      from s in PageStar,
        where: s.user_id == ^user.id and s.page_id == ^page.id
    )
  end

  def count_page_stars(page) do
    Repo.aggregate(
      from(s in PageStar, where: s.page_id == ^page.id),
      :count
    )
  end

  # --- Collection functions ---

  def list_collections(community) do
    from(c in Collection,
      where: c.community_id == ^community.id,
      order_by: [c.sort_order, c.name]
    )
    |> Repo.all()
  end

  def get_collection!(id), do: Repo.get!(Collection, id)

  def create_collection(community, attrs) do
    %Collection{}
    |> Collection.changeset(Map.put(attrs, "community_id", community.id))
    |> Repo.insert()
  end

  def update_collection(%Collection{} = collection, attrs) do
    collection
    |> Collection.changeset(attrs)
    |> Repo.update()
  end

  def delete_collection(%Collection{} = collection) do
    Repo.delete(collection)
  end

  def change_collection(%Collection{} = collection \\ %Collection{}, attrs \\ %{}) do
    Collection.changeset(collection, attrs)
  end

  def reorder_collections(ids) when is_list(ids) do
    ids
    |> Enum.with_index()
    |> Enum.each(fn {id, idx} ->
      from(c in Collection, where: c.id == ^id)
      |> Repo.update_all(set: [sort_order: idx])
    end)

    :ok
  end

  def reorder_pages(ids) when is_list(ids) do
    ids
    |> Enum.with_index()
    |> Enum.each(fn {id, idx} ->
      from(p in Page, where: p.id == ^id)
      |> Repo.update_all(set: [sort_order: idx])
    end)

    :ok
  end

  def assign_page_to_collection(%Page{} = page, collection_id) do
    page
    |> Page.changeset(%{collection_id: collection_id})
    |> Repo.update()
  end

  def remove_page_from_collection(%Page{} = page) do
    page
    |> Page.changeset(%{collection_id: nil})
    |> Repo.update()
  end

  # --- Page functions ---

  def get_page_by_slugs(community_name, page_slug) do
    query =
      from(p in Page,
        join: c in Community,
        on: c.id == p.community_id,
        where: c.name == ^community_name and p.slug == ^page_slug,
        preload: [:community, :owner, sections: ^from(s in Section, order_by: s.sort_order)]
      )

    case Repo.one(query) do
      nil -> {:error, :not_found}
      page -> {:ok, page}
    end
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

  def get_section(id) do
    case Repo.get(Section, id) do
      nil -> {:error, :not_found}
      section -> {:ok, Repo.preload(section, proposals: [:author])}
    end
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
      |> upsert_sections(splits, existing, page.id)
      |> cleanup_extra_sections(existing, length(splits))

    case Repo.transaction(multi) do
      {:ok, _results} ->
        {:ok, list_sections(page.id)}

      {:error, _key, reason, _changes} ->
        {:error, reason}
    end
  end

  defp upsert_sections(multi, splits, existing, page_id) do
    splits
    |> Enum.with_index()
    |> Enum.reduce(multi, fn {content, idx}, multi ->
      upsert_section(multi, Enum.at(existing, idx), content, idx, page_id)
    end)
  end

  defp upsert_section(multi, nil, content, idx, page_id) do
    Ecto.Multi.insert(multi, {:section, idx}, fn _changes ->
      Section.changeset(%Section{}, %{content: content, sort_order: idx, page_id: page_id})
    end)
  end

  defp upsert_section(multi, section, content, idx, _page_id) do
    Ecto.Multi.update(multi, {:section, idx}, fn _changes ->
      Section.changeset(section, %{content: content, sort_order: idx})
    end)
  end

  defp cleanup_extra_sections(multi, existing, keep_count) do
    sections_to_check = Enum.drop(existing, keep_count)

    if sections_to_check == [] do
      multi
    else
      Ecto.Multi.run(multi, :cleanup_sections, fn repo, _changes ->
        section_ids = Enum.map(sections_to_check, & &1.id)

        ids_with_pending =
          from(p in Proposal,
            where: p.section_id in ^section_ids and p.status == "pending",
            select: p.section_id
          )
          |> repo.all()
          |> MapSet.new()

        for section <- sections_to_check,
            !MapSet.member?(ids_with_pending, section.id) do
          repo.delete!(section)
        end

        {:ok, :cleaned}
      end)
    end
  end

  def split_blocks_into_sections(blocks) when is_list(blocks) do
    {sections_reversed, current_blocks} =
      Enum.reduce(blocks, {[], []}, fn block, {sections, acc} ->
        split_block(block, sections, acc)
      end)

    Enum.reverse([Enum.reverse(current_blocks) | sections_reversed])
  end

  defp split_block(block, sections, acc) do
    is_section_heading =
      block["type"] == "heading" and get_in(block, ["props", "level"]) in [1, 2]

    case {is_section_heading, acc} do
      {true, []} -> {sections, [block]}
      {true, _} -> {[Enum.reverse(acc) | sections], [block]}
      {false, _} -> {sections, [block | acc]}
    end
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

  def extract_headings(sections) when is_list(sections) do
    sections
    |> Enum.sort_by(& &1.sort_order)
    |> Enum.flat_map(fn section ->
      (section.content || [])
      |> Enum.filter(fn block ->
        block["type"] == "heading" and block["id"]
      end)
      |> Enum.map(fn block ->
        %{
          id: block["id"],
          text: get_in(block, ["content", Access.at(0), "text"]) || "Untitled",
          level: get_in(block, ["props", "level"]) || 1
        }
      end)
    end)
  end

  def slugify(title) when is_binary(title) do
    title
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/, "")
    |> String.trim()
    |> String.replace(~r/\s+/, "-")
    |> String.replace(~r/-+/, "-")
    |> String.trim("-")
  end

  def slugify(_), do: ""

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
              'MaxWords=30, MinWords=15, StartSel=«mark», StopSel=«/mark»')
            """,
            s.content,
            ^query
          )
      }
    )
    |> Repo.all()
    |> Enum.map(&sanitize_snippet/1)
  end

  def search_community_content(_community, _query), do: []

  defp sanitize_snippet(%{snippet: snippet} = result) when is_binary(snippet) do
    safe_snippet =
      snippet
      |> Phoenix.HTML.html_escape()
      |> Phoenix.HTML.safe_to_string()
      |> String.replace("«mark»", "<mark>")
      |> String.replace("«/mark»", "</mark>")

    %{result | snippet: safe_snippet}
  end

  defp sanitize_snippet(result), do: result

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

  def create_page_proposal(community, author, attrs) do
    %Proposal{}
    |> Proposal.page_proposal_changeset(
      attrs
      |> Map.put(:community_id, community.id)
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

  defp community_proposals_query(community) do
    from(pr in Proposal,
      left_join: s in Section,
      on: s.id == pr.section_id,
      left_join: p in Page,
      on: p.id == s.page_id,
      where: p.community_id == ^community.id or pr.community_id == ^community.id
    )
  end

  def list_community_proposals(community, status \\ "all") do
    query =
      community_proposals_query(community)
      |> preload([:author, :community, :collection, section: :page])
      |> order_by([pr], desc: pr.inserted_at)

    query =
      if status != "all",
        do: where(query, [pr], pr.status == ^status),
        else: query

    Repo.all(query)
  end

  def count_community_pending_proposals(community) do
    community_proposals_query(community)
    |> where([pr], pr.status == "pending")
    |> select([pr], count(pr.id))
    |> Repo.one()
  end

  def count_community_proposals_by_status(community) do
    community_proposals_query(community)
    |> group_by([pr], pr.status)
    |> select([pr], {pr.status, count(pr.id)})
    |> Repo.all()
    |> Map.new()
  end

  def get_proposal(id) do
    case Repo.get(Proposal, id) do
      nil ->
        {:error, :not_found}

      proposal ->
        {:ok,
         Repo.preload(proposal, [
           :section,
           :author,
           :reviewed_by,
           :community,
           :collection,
           comments: [:author]
         ])}
    end
  end

  def approve_proposal(proposal, reviewer) do
    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.update(:proposal, fn _changes ->
        Proposal.review_changeset(proposal, %{
          status: "approved",
          reviewed_by_id: reviewer.id,
          reviewed_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })
      end)

    multi =
      if Proposal.new_page_proposal?(proposal) do
        multi
        |> Ecto.Multi.insert(:page, fn _changes ->
          Page.changeset(%Page{}, %{
            title: proposal.proposed_title,
            slug: proposal.proposed_slug,
            community_id: proposal.community_id,
            owner_id: proposal.author_id,
            collection_id: proposal.collection_id
          })
        end)
        |> Ecto.Multi.run(:sections, fn _repo, %{page: page} ->
          save_page_content(page, proposal.proposed_content || [])
        end)
      else
        Ecto.Multi.run(multi, :sections, fn repo, %{proposal: proposal} ->
          case repo.get(Section, proposal.section_id) do
            nil -> {:error, :not_found}
            section -> apply_proposed_content(repo, section, proposal.proposed_content)
          end
        end)
      end

    Repo.transaction(multi)
  end

  defp apply_proposed_content(_repo, section, []), do: {:ok, [section]}

  defp apply_proposed_content(repo, section, proposed_content) do
    [first_content | rest] = split_blocks_into_sections(proposed_content)

    shift_sections_for_splits(repo, section, length(rest))

    with {:ok, updated} <-
           section
           |> Section.changeset(%{content: first_content})
           |> repo.update(),
         {:ok, new_sections} <- insert_split_sections(repo, rest, section) do
      {:ok, [updated | new_sections]}
    end
  end

  defp insert_split_sections(_repo, [], _section), do: {:ok, []}

  defp insert_split_sections(repo, rest, section) do
    Enum.reduce_while(rest |> Enum.with_index(1), {:ok, []}, fn {content, idx}, {:ok, acc} ->
      case %Section{}
           |> Section.changeset(%{
             content: content,
             sort_order: section.sort_order + idx,
             page_id: section.page_id
           })
           |> repo.insert() do
        {:ok, new_section} -> {:cont, {:ok, acc ++ [new_section]}}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  defp shift_sections_for_splits(_repo, _section, 0), do: :ok

  defp shift_sections_for_splits(repo, section, count) do
    from(s in Section,
      where: s.page_id == ^section.page_id and s.sort_order > ^section.sort_order
    )
    |> repo.update_all(inc: [sort_order: count])
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

  # --- Page comment functions ---

  def list_page_comments(page) do
    from(c in PageComment,
      where: c.page_id == ^page.id and is_nil(c.parent_id),
      order_by: [asc: c.inserted_at],
      preload: [:author, replies: [:author]]
    )
    |> Repo.all()
  end

  def count_page_comments(page) do
    from(c in PageComment, where: c.page_id == ^page.id)
    |> Repo.aggregate(:count)
  end

  def add_page_comment(page, author, attrs) do
    %PageComment{}
    |> PageComment.changeset(
      attrs
      |> Map.put(:page_id, page.id)
      |> Map.put(:author_id, author.id)
    )
    |> Repo.insert()
  end

  def reply_to_page_comment(page, parent, author, attrs) do
    if parent.parent_id != nil do
      {:error, :no_nested_replies}
    else
      %PageComment{}
      |> PageComment.changeset(
        attrs
        |> Map.put(:page_id, page.id)
        |> Map.put(:author_id, author.id)
        |> Map.put(:parent_id, parent.id)
      )
      |> Repo.insert()
    end
  end

  def delete_page_comment(comment) do
    Repo.delete(comment)
  end

  def get_page_comment(id) do
    case Repo.get(PageComment, id) do
      nil -> {:error, :not_found}
      comment -> {:ok, Repo.preload(comment, :author)}
    end
  end
end
