# Service Layer Refactor Plan

## Context

The codebase currently uses context modules (`PagesContext`, `CommentsContext`, `CommunityManager`, etc.) that bundle all CRUD operations together. As the app grows, these modules are becoming large and mixing concerns (authorization, side effects, DB writes). The goal is to introduce a **service layer** where each write operation gets its own module with a `call/N` entry point, making operations focused, testable, and auditable.

Read-only operations (list, search, get, pagination) stay in the existing context modules — they don't need the service treatment.

---

## Current Structure

```
lib/atlas/communities/
  community_manager.ex    # Atlas.Communities.CommunityManager
  pages_context.ex        # Atlas.Communities.PagesContext
  collections_context.ex  # Atlas.Communities.CollectionsContext
  comments_context.ex     # Atlas.Communities.CommentsContext
  reports_context.ex      # Atlas.Communities.ReportsContext
  restrictions_context.ex # Atlas.Communities.RestrictionsContext
  proposals.ex            # Atlas.Communities.Proposals
  sections.ex             # Atlas.Communities.Sections
  stars.ex                # Atlas.Communities.Stars
```

---

## Proposed Services by Domain

Each service module lives under its domain namespace and exposes `call/N` returning `{:ok, result} | {:error, reason}`.

### Communities

| Current call | Proposed service | Source LiveView |
|---|---|---|
| `CommunityManager.create_community/2` | `Atlas.Communities.Community.Create` | `CommunityLive.Form` |
| `CommunityManager.update_community/2` | `Atlas.Communities.Community.Update` | `Moderation.General` |
| `CommunityManager.join_community/2` | `Atlas.Communities.Community.Join` | `CommunityLive.Show` |
| `CommunityManager.leave_community/2` | `Atlas.Communities.Community.Leave` | `CommunityLive.Show` |

### Pages

| Current call | Proposed service | Source LiveView |
|---|---|---|
| `PagesContext.create_page/2` | `Atlas.Communities.Page.Create` | `PageLive.Form` |
| `PagesContext.update_page/2` + `Sections.save_page_content/2` | `Atlas.Communities.Page.Update` | `PageLive.Edit` |
| `PagesContext.reorder_pages/2` | `Atlas.Communities.Page.Reorder` | `CommunityLive.Collections` |

### Collections

| Current call | Proposed service | Source LiveView |
|---|---|---|
| `CollectionsContext.create_collection/2` | `Atlas.Communities.Collection.Create` | `CommunityLive.Collections` |
| `CollectionsContext.delete_collection/1` | `Atlas.Communities.Collection.Delete` | `CommunityLive.Collections` |
| `CollectionsContext.reorder_collections/2` | `Atlas.Communities.Collection.Reorder` | `CommunityLive.Collections` |
| `CollectionsContext.assign_page_to_collection/2` / `remove_page_from_collection/1` | `Atlas.Communities.Collection.MovePage` | `CommunityLive.Collections` |

### Proposals

| Current call | Proposed service | Source LiveView |
|---|---|---|
| `Proposals.create_proposal/3` | `Atlas.Communities.Proposal.Create` | `PageLive.Propose` |
| `Proposals.create_page_proposal/3` | `Atlas.Communities.Proposal.CreatePage` | `PageLive.ProposeNew` |
| `Proposals.update_proposal/2` / `update_page_proposal/2` | `Atlas.Communities.Proposal.Update` | `ProposalLive.Edit` |
| `Proposals.approve_proposal/2` | `Atlas.Communities.Proposal.Approve` | `ProposalLive.Show`, `Moderation.Queues` |
| `Proposals.reject_proposal/2` | `Atlas.Communities.Proposal.Reject` | `ProposalLive.Show`, `Moderation.Queues` |

### Comments

| Current call | Proposed service | Source LiveView |
|---|---|---|
| `CommentsContext.add_comment/3` | `Atlas.Communities.Comment.Create` | `CommentsSection` |
| `CommentsContext.reply_to_comment/4` | `Atlas.Communities.Comment.Reply` | `CommentsSection` |
| `CommentsContext.delete_comment/1` | `Atlas.Communities.Comment.Delete` | `CommentsSection` |
| `CommentsContext.vote_comment/3` / `unvote_comment/2` | `Atlas.Communities.Comment.Vote` | `CommentsSection` |

### Stars

| Current call | Proposed service | Source LiveView |
|---|---|---|
| `Stars.star_page/2` | `Atlas.Communities.Star.Create` | `CommunityLive.Show` |
| `Stars.unstar_page/2` | `Atlas.Communities.Star.Delete` | `CommunityLive.Show` |

### Reports

| Current call | Proposed service | Source LiveView |
|---|---|---|
| `ReportsContext.create_report/2` | `Atlas.Communities.Report.Create` | `CommunityLive.Show`, `CommunityLive.About`, `UserLive.Profile` |
| `ReportsContext.resolve_report/2` | `Atlas.Communities.Report.Resolve` | `Moderation.Reports` |
| `ReportsContext.remove_reported_content/2` | `Atlas.Communities.Report.RemoveContent` | `Moderation.Reports` |

### Moderation

| Current call | Proposed service | Source LiveView |
|---|---|---|
| `CommunityManager.set_member_role/3` | `Atlas.Communities.Moderation.SetRole` | `Moderation.TeamMembers` |
| `RestrictionsContext.create_restriction/4` | `Atlas.Communities.Moderation.RestrictUser` | `Moderation.RestrictedUsers` |
| `RestrictionsContext.delete_restriction/1` | `Atlas.Communities.Moderation.UnrestrictUser` | `Moderation.RestrictedUsers` |

### Accounts (outside communities domain)

| Current call | Proposed service | Source LiveView |
|---|---|---|
| `Accounts.register_user/1` | `Atlas.Accounts.User.Register` | `UserLive.Registration` |
| `Accounts.update_user_avatar/2` | `Atlas.Accounts.User.UpdateAvatar` | `UserLive.Settings` |
| `Accounts.delete_user/1` | `Atlas.Accounts.User.Delete` | `UserLive.Settings` |
| `Accounts.change_user_email/2` | `Atlas.Accounts.User.ChangeEmail` | `UserLive.Settings` |
| `Accounts.change_user_password/2` | `Atlas.Accounts.User.ChangePassword` | `UserLive.Settings` |

---

## File Structure

```
lib/atlas/communities/
  community/
    create.ex
    update.ex
    join.ex
    leave.ex
  page/
    create.ex
    update.ex
    reorder.ex
  collection/
    create.ex
    delete.ex
    reorder.ex
    move_page.ex
  proposal/
    create.ex
    create_page.ex
    update.ex
    approve.ex
    reject.ex
  comment/
    create.ex
    reply.ex
    delete.ex
    vote.ex
  star/
    create.ex
    delete.ex
  report/
    create.ex
    resolve.ex
    remove_content.ex
  moderation/
    set_role.ex
    restrict_user.ex
    unrestrict_user.ex

lib/atlas/accounts/
  user/
    register.ex
    update_avatar.ex
    delete.ex
    change_email.ex
    change_password.ex
```

---

## Module Pattern

Each service owns authorization + business logic and follows this shape:

```elixir
defmodule Atlas.Communities.Comment.Delete do
  alias Atlas.Repo
  alias Atlas.Communities.Comment
  alias Atlas.Authorization

  def call(comment_id, actor) do
    comment = Repo.get!(Comment, comment_id)

    with :ok <- authorize(comment, actor) do
      Ecto.Multi.new()
      |> Ecto.Multi.delete(:comment, comment)
      |> Repo.transaction()
    end
  end

  defp authorize(comment, actor) do
    if comment.author_id == actor.id or Authorization.can_moderate?(actor, comment) do
      :ok
    else
      {:error, :unauthorized}
    end
  end
end
```

LiveViews still gate UI visibility (hide buttons, guard mounts) but the service is the **single source of truth** for whether an operation is allowed. This means a LiveView call looks like:

```elixir
case Atlas.Communities.Comment.Delete.call(comment_id, current_user) do
  {:ok, _} -> {:noreply, put_flash(socket, :info, "Deleted")}
  {:error, :unauthorized} -> {:noreply, put_flash(socket, :error, "Not allowed")}
  {:error, _} -> {:noreply, put_flash(socket, :error, "Something went wrong")}
end
```

---

## What Stays in Context Modules

Read-only operations remain where they are:

- `CommentsContext.list_comments/3`, `get_comment/1`, `list_replies/2`
- `PagesContext.get_page_by_slugs/2`, `search_pages/2`
- `CommunityManager.list_communities/1`, `search_communities/2`, `get_community_by_name/1`
- `Proposals.list_community_proposals/3`, `list_user_proposals/3`
- `ReportsContext.list_community_reports/3`
- `RestrictionsContext.list_community_restrictions/2`
- All pagination / filtering queries

---

## Migration Strategy

This is a gradual refactor — not a big bang:

1. Pick one domain (e.g., Comments) and extract its write operations into services
2. Update the LiveView to call the service instead of the context
3. Verify everything works
4. Repeat for the next domain
5. Once all writes are extracted, slim down the context modules to reads only

---

## Decisions

- **Authorization:** Lives in the service modules. Services are the single source of truth. LiveViews still gate UI (hide buttons etc.) but don't duplicate auth logic.
- **Audit logging:** Separate follow-up. This refactor focuses purely on extracting the service layer. Audit log table + wiring into moderation services comes after.
