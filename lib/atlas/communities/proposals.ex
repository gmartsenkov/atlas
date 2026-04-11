defmodule Atlas.Communities.Proposals do
  @moduledoc false
  import Ecto.Query

  alias Atlas.Communities.{Comment, Page, Proposal, Section}
  alias Atlas.Communities.Sections, as: SectionsCtx
  alias Atlas.Pagination
  alias Atlas.Repo

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

  def list_pending_proposals(page, opts \\ []) do
    from(pr in Proposal,
      join: s in Section,
      on: s.id == pr.section_id,
      where: s.page_id == ^page.id and pr.status == "pending",
      preload: [:author, :section],
      order_by: [desc: pr.inserted_at]
    )
    |> Pagination.paginate(opts)
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

  @valid_proposal_statuses ~w(all pending approved rejected)

  def list_community_proposals(community, status \\ "all", opts \\ []) do
    status = if status in @valid_proposal_statuses, do: status, else: "all"

    query =
      community_proposals_query(community)
      |> preload([:author, :community, :collection, section: :page])
      |> order_by([pr], desc: pr.inserted_at)

    query =
      if status != "all",
        do: where(query, [pr], pr.status == ^status),
        else: query

    Pagination.paginate(query, opts)
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
           comments:
             from(c in Comment,
               where: is_nil(c.parent_id),
               order_by: c.inserted_at,
               limit: 500,
               preload: [
                 :author,
                 replies:
                   ^from(r in Comment, order_by: r.inserted_at, limit: 50, preload: :author)
               ]
             )
         ])}
    end
  end

  def approve_proposal(%Proposal{status: "pending"} = proposal, reviewer) do
    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.run(:proposal, fn repo, _changes ->
        case repo.one(from(p in Proposal, where: p.id == ^proposal.id and p.status == "pending")) do
          nil ->
            {:error, :not_pending}

          fresh_proposal ->
            fresh_proposal
            |> Proposal.review_changeset(%{
              status: "approved",
              reviewed_by_id: reviewer.id,
              reviewed_at: DateTime.utc_now() |> DateTime.truncate(:second)
            })
            |> repo.update()
        end
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
          SectionsCtx.save_page_content(page, proposal.proposed_content || [])
        end)
      else
        Ecto.Multi.run(multi, :sections, fn repo, %{proposal: approved} ->
          update_section_content(repo, approved)
        end)
      end

    Repo.transaction(multi)
  end

  def approve_proposal(_proposal, _reviewer), do: {:error, :not_pending}

  defp update_section_content(repo, proposal) do
    case repo.get(Section, proposal.section_id) do
      nil -> {:error, :not_found}
      section -> apply_proposed_content(repo, section, proposal.proposed_content)
    end
  end

  defp apply_proposed_content(_repo, section, []), do: {:ok, [section]}

  defp apply_proposed_content(repo, section, proposed_content) do
    [first_content | rest] = SectionsCtx.split_blocks_into_sections(proposed_content)

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
    result =
      Enum.reduce_while(rest |> Enum.with_index(1), {:ok, []}, fn {content, idx}, {:ok, acc} ->
        case %Section{}
             |> Section.changeset(%{
               content: content,
               sort_order: section.sort_order + idx,
               page_id: section.page_id
             })
             |> repo.insert() do
          {:ok, new_section} -> {:cont, {:ok, [new_section | acc]}}
          {:error, _} = error -> {:halt, error}
        end
      end)

    case result do
      {:ok, sections} -> {:ok, Enum.reverse(sections)}
      error -> error
    end
  end

  defp shift_sections_for_splits(_repo, _section, 0), do: :ok

  defp shift_sections_for_splits(repo, section, count) do
    from(s in Section,
      where: s.page_id == ^section.page_id and s.sort_order > ^section.sort_order
    )
    |> repo.update_all(inc: [sort_order: count])
  end

  def reject_proposal(%Proposal{status: "pending"} = proposal, reviewer) do
    proposal
    |> Proposal.review_changeset(%{
      status: "rejected",
      reviewed_by_id: reviewer.id,
      reviewed_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
    |> Repo.update()
  end

  def reject_proposal(_proposal, _reviewer), do: {:error, :not_pending}

  def update_proposal(%Proposal{status: "pending"} = proposal, attrs) do
    proposal
    |> Proposal.edit_changeset(attrs)
    |> Repo.update()
  end

  def update_proposal(_proposal, _attrs), do: {:error, :not_pending}

  def update_page_proposal(%Proposal{status: "pending"} = proposal, attrs) do
    proposal
    |> Proposal.edit_page_proposal_changeset(attrs)
    |> Repo.update()
  end

  def update_page_proposal(_proposal, _attrs), do: {:error, :not_pending}

  def list_user_proposals(user, status \\ "all", opts \\ []) do
    status = if status in @valid_proposal_statuses, do: status, else: "all"

    query =
      from(pr in Proposal,
        where: pr.author_id == ^user.id,
        preload: [:author, :community, :collection, section: [page: :community]],
        order_by: [desc: pr.inserted_at]
      )

    query =
      if status != "all",
        do: where(query, [pr], pr.status == ^status),
        else: query

    Pagination.paginate(query, opts)
  end

  def count_user_proposals_by_status(user) do
    from(pr in Proposal,
      where: pr.author_id == ^user.id,
      group_by: pr.status,
      select: {pr.status, count(pr.id)}
    )
    |> Repo.all()
    |> Map.new()
  end
end
