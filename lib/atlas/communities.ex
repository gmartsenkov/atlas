defmodule Atlas.Communities do
  @moduledoc false

  alias Atlas.Communities.{
    CollectionsContext,
    CommentsContext,
    CommunityManager,
    PagesContext,
    Proposals,
    ReportsContext,
    RestrictionsContext,
    Search,
    Sections,
    Stars
  }

  # Community management
  defdelegate list_communities(opts \\ []), to: CommunityManager
  defdelegate search_communities(query, opts \\ []), to: CommunityManager
  defdelegate get_community_by_name(name), to: CommunityManager
  defdelegate create_community(attrs, owner), to: CommunityManager
  defdelegate change_community, to: CommunityManager
  defdelegate change_community(community, attrs), to: CommunityManager
  defdelegate update_community(community, attrs), to: CommunityManager
  defdelegate change_community_edit(community), to: CommunityManager
  defdelegate change_community_edit(community, attrs), to: CommunityManager
  defdelegate join_community(user, community), to: CommunityManager
  defdelegate leave_community(user, community), to: CommunityManager
  defdelegate member?(user, community), to: CommunityManager
  defdelegate moderator?(user, community), to: CommunityManager
  defdelegate set_member_role(community, user_id, role), to: CommunityManager
  defdelegate community_member_roles(community), to: CommunityManager
  defdelegate list_community_members(community, opts \\ []), to: CommunityManager
  defdelegate list_community_moderators(community), to: CommunityManager
  defdelegate search_community_members(community, query), to: CommunityManager
  defdelegate list_user_communities(user, limit \\ 6), to: CommunityManager
  defdelegate list_user_moderated_communities(user), to: CommunityManager

  # Pages
  defdelegate get_page_by_slugs(community_name, page_slug), to: PagesContext
  defdelegate create_page(attrs, owner), to: PagesContext
  defdelegate update_page(page, attrs), to: PagesContext
  defdelegate change_page(page, attrs), to: PagesContext
  defdelegate reorder_pages(community, ids), to: PagesContext

  # Sections
  defdelegate list_sections(page_id), to: Sections
  defdelegate get_section(id), to: Sections
  defdelegate save_page_content(page, blocks), to: Sections
  defdelegate split_blocks_into_sections(blocks), to: Sections
  defdelegate merge_sections_content(sections), to: Sections
  defdelegate title_from_blocks(blocks), to: Sections
  defdelegate section_title(section), to: Sections
  defdelegate extract_headings(sections), to: Sections
  defdelegate slugify(title), to: Sections

  # Collections
  defdelegate list_collections(community), to: CollectionsContext
  defdelegate get_collection(id), to: CollectionsContext
  defdelegate create_collection(community, attrs), to: CollectionsContext
  defdelegate delete_collection(collection), to: CollectionsContext
  defdelegate reorder_collections(community, ids), to: CollectionsContext
  defdelegate assign_page_to_collection(page, collection_id), to: CollectionsContext
  defdelegate remove_page_from_collection(page), to: CollectionsContext

  # Stars
  defdelegate star_page(user, page), to: Stars
  defdelegate unstar_page(user, page), to: Stars
  defdelegate page_starred?(user, page), to: Stars
  defdelegate count_page_stars(page), to: Stars

  # Search
  defdelegate search_community_content(community, query), to: Search

  # Proposals
  defdelegate create_proposal(section, author, attrs), to: Proposals
  defdelegate create_page_proposal(community, author, attrs), to: Proposals
  defdelegate list_pending_proposals(page, opts \\ []), to: Proposals
  defdelegate count_pending_proposals(page), to: Proposals
  defdelegate list_community_proposals(community, status \\ "all", opts \\ []), to: Proposals
  defdelegate count_community_pending_proposals(community), to: Proposals
  defdelegate count_community_proposals_by_status(community), to: Proposals
  defdelegate get_proposal(id), to: Proposals
  defdelegate approve_proposal(proposal, reviewer), to: Proposals
  defdelegate reject_proposal(proposal, reviewer), to: Proposals
  defdelegate update_proposal(proposal, attrs), to: Proposals
  defdelegate update_page_proposal(proposal, attrs), to: Proposals
  defdelegate list_user_proposals(user, status \\ "all", opts \\ []), to: Proposals
  defdelegate count_user_proposals_by_status(user), to: Proposals
  # Reports
  defdelegate create_report(reporter, attrs), to: ReportsContext

  defdelegate list_community_reports(community, status \\ "pending", opts \\ []),
    to: ReportsContext

  defdelegate count_community_reports_by_status(community), to: ReportsContext
  defdelegate get_report(id), to: ReportsContext
  defdelegate resolve_report(report, resolver), to: ReportsContext
  defdelegate remove_reported_content(report, resolver), to: ReportsContext

  # Restrictions
  defdelegate list_community_restrictions(community, opts \\ []), to: RestrictionsContext
  defdelegate create_restriction(community, user, restricted_by, attrs), to: RestrictionsContext
  defdelegate delete_restriction(restriction), to: RestrictionsContext
  defdelegate get_restriction(id), to: RestrictionsContext

  # Comment votes
  defdelegate vote_comment(user, comment_id, value), to: CommentsContext
  defdelegate unvote_comment(user, comment_id), to: CommentsContext
  defdelegate comment_scores(comment_ids), to: CommentsContext
  defdelegate user_votes(user, comment_ids), to: CommentsContext

  # Comments
  defdelegate count_comments(commentable), to: CommentsContext
  defdelegate list_comments(commentable, opts \\ []), to: CommentsContext
  defdelegate add_comment(commentable, author, attrs), to: CommentsContext
  defdelegate reply_to_comment(commentable, parent, author, attrs), to: CommentsContext
  defdelegate delete_comment(comment), to: CommentsContext

  # Alias for dashboard moderator action
  defdelegate redact_comment(comment), to: CommentsContext, as: :delete_comment
  defdelegate get_comment(id), to: CommentsContext
  defdelegate get_comment_with_replies(id, opts \\ []), to: CommentsContext
  defdelegate count_replies(parent_id), to: CommentsContext
  defdelegate list_replies(parent_id, opts \\ []), to: CommentsContext
end
