defmodule Atlas.Authorization do
  @moduledoc false

  alias Atlas.Communities.{Community, Page, PageComment}

  def can_edit_community?(nil, _community), do: false
  def can_edit_community?(user, %Community{} = community), do: community.owner_id == user.id

  def can_manage_collections?(user, community, is_moderator \\ false) do
    can_edit_community?(user, community) || is_moderator
  end

  def can_create_page?(user, community, is_moderator \\ false) do
    can_edit_community?(user, community) || is_moderator
  end

  def can_edit_page?(user, page, community, is_moderator \\ false)
  def can_edit_page?(nil, _page, _community, _is_moderator), do: false

  def can_edit_page?(user, %Page{} = page, %Community{} = community, is_moderator) do
    page.owner_id == user.id || community.owner_id == user.id || is_moderator
  end

  def can_view_proposals?(user, page, is_moderator \\ false)
  def can_view_proposals?(nil, _page, _is_moderator), do: false

  def can_view_proposals?(user, %Page{} = page, is_moderator) do
    page.owner_id == user.id || is_moderator
  end

  def can_review_proposal?(user, community, page, is_moderator \\ false)
  def can_review_proposal?(nil, _community, _page, _is_moderator), do: false

  def can_review_proposal?(user, %Community{} = community, nil, is_moderator) do
    community.owner_id == user.id || is_moderator
  end

  def can_review_proposal?(user, _community, %Page{} = page, is_moderator) do
    page.owner_id == user.id || is_moderator
  end

  def can_propose?(community), do: community.suggestions_enabled == true

  def can_delete_comment?(user, comment, page, is_moderator \\ false)
  def can_delete_comment?(nil, _comment, _page, _is_moderator), do: false

  def can_delete_comment?(user, %PageComment{} = comment, %Page{} = page, is_moderator) do
    comment.author_id == user.id || page.owner_id == user.id || is_moderator
  end

  def can_edit_proposal?(nil, _proposal, _community, _is_moderator), do: false

  def can_edit_proposal?(user, proposal, community, is_moderator) do
    proposal.author_id == user.id || community.owner_id == user.id || is_moderator
  end

  def community_owner?(nil, _community), do: false
  def community_owner?(user, %Community{} = community), do: community.owner_id == user.id

  def page_owner?(nil, _page), do: false
  def page_owner?(user, %Page{} = page), do: page.owner_id == user.id
end
