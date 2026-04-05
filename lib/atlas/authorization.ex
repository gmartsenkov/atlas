defmodule Atlas.Authorization do
  @moduledoc false

  alias Atlas.Communities.{Community, Page, PageComment}

  def can_edit_community?(nil, _community), do: false
  def can_edit_community?(user, %Community{} = community), do: community.owner_id == user.id

  def can_manage_collections?(user, community), do: can_edit_community?(user, community)

  def can_create_page?(user, community), do: can_edit_community?(user, community)

  def can_edit_page?(nil, _page, _community), do: false

  def can_edit_page?(user, %Page{} = page, %Community{} = community) do
    page.owner_id == user.id || community.owner_id == user.id
  end

  def can_view_proposals?(nil, _page), do: false
  def can_view_proposals?(user, %Page{} = page), do: page.owner_id == user.id

  def can_review_proposal?(nil, _community, _page), do: false

  def can_review_proposal?(user, %Community{} = community, nil) do
    # Page proposals — community owner reviews
    community.owner_id == user.id
  end

  def can_review_proposal?(user, _community, %Page{} = page) do
    # Section proposals — page owner reviews
    page.owner_id == user.id
  end

  def can_propose?(community), do: community.suggestions_enabled == true

  def can_delete_comment?(nil, _comment, _page), do: false

  def can_delete_comment?(user, %PageComment{} = comment, %Page{} = page) do
    comment.author_id == user.id || page.owner_id == user.id
  end

  def community_owner?(nil, _community), do: false
  def community_owner?(user, %Community{} = community), do: community.owner_id == user.id

  def page_owner?(nil, _page), do: false
  def page_owner?(user, %Page{} = page), do: page.owner_id == user.id
end
