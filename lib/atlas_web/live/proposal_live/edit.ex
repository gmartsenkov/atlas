defmodule AtlasWeb.ProposalLive.Edit do
  use AtlasWeb, :live_view

  alias Atlas.Authorization

  alias Atlas.Communities.{
    CollectionsContext,
    CommunityManager,
    PagesContext,
    Proposals,
    Sections
  }

  alias Atlas.Communities.Proposal.Update

  import AtlasWeb.BlockRenderer

  # Section proposal edit
  @impl true
  def mount(
        %{"community_name" => community_name, "page_slug" => page_slug, "id" => id},
        _session,
        socket
      ) do
    with {:ok, community} <- CommunityManager.get_community_by_name(community_name),
         {:ok, page} <- PagesContext.get_page_by_slugs(community_name, page_slug),
         {:ok, proposal} <- Proposals.get_proposal(id),
         true <- proposal.section != nil and proposal.section.page_id == page.id do
      current_user = socket.assigns.current_scope.user
      is_moderator = CommunityManager.moderator?(current_user, community)

      if Authorization.can_edit_proposal?(current_user, proposal, community, is_moderator) do
        all_sections = Sections.list_sections(page.id)

        sections_before =
          Enum.filter(all_sections, &(&1.sort_order < proposal.section.sort_order))

        sections_after =
          Enum.filter(all_sections, &(&1.sort_order > proposal.section.sort_order))

        {:ok,
         assign(socket,
           page_title: "Edit Proposal",
           community: community,
           page: page,
           proposal: proposal,
           sections_before: sections_before,
           sections_after: sections_after,
           proposed_content: proposal.proposed_content || [],
           is_page_proposal: false
         )}
      else
        {:ok,
         socket
         |> put_flash(:error, "You don't have permission to edit this proposal.")
         |> push_navigate(to: ~p"/c/#{community.name}/#{page.slug}/proposals/#{id}")}
      end
    else
      {:error, :not_found} -> raise AtlasWeb.NotFoundError
      false -> raise AtlasWeb.NotFoundError
    end
  end

  # New-page proposal edit
  def mount(
        %{"community_name" => community_name, "id" => id},
        _session,
        socket
      ) do
    with {:ok, community} <- CommunityManager.get_community_by_name(community_name),
         {:ok, proposal} <- Proposals.get_proposal(id),
         true <- proposal.community_id == community.id do
      current_user = socket.assigns.current_scope.user
      is_moderator = CommunityManager.moderator?(current_user, community)

      if Authorization.can_edit_proposal?(current_user, proposal, community, is_moderator) do
        collections = CollectionsContext.list_collections(community)

        {:ok,
         assign(socket,
           page_title: "Edit Page Proposal",
           community: community,
           page: nil,
           proposal: proposal,
           collections: collections,
           title: proposal.proposed_title || "",
           slug: proposal.proposed_slug || "",
           collection_id: proposal.collection_id,
           proposed_content: proposal.proposed_content || [],
           is_page_proposal: true
         )}
      else
        {:ok,
         socket
         |> put_flash(:error, "You don't have permission to edit this proposal.")
         |> push_navigate(to: ~p"/c/#{community.name}/page-proposals/#{id}")}
      end
    else
      {:error, :not_found} -> raise AtlasWeb.NotFoundError
      false -> raise AtlasWeb.NotFoundError
    end
  end

  @impl true
  def handle_event("editor-updated", %{"blocks" => blocks}, socket) do
    {:noreply, assign(socket, proposed_content: blocks)}
  end

  def handle_event("validate", %{"value" => title}, socket) do
    slug = Sections.slugify(title)
    {:noreply, assign(socket, title: title, slug: slug)}
  end

  def handle_event("validate", %{"collection_id" => collection_id}, socket) do
    {:noreply, assign(socket, collection_id: parse_collection_id(collection_id))}
  end

  def handle_event("save-proposal", _params, socket) do
    proposal = socket.assigns.proposal

    if socket.assigns.is_page_proposal do
      save_page_proposal(socket, proposal)
    else
      save_section_proposal(socket, proposal)
    end
  end

  defp save_section_proposal(socket, proposal) do
    proposed_content = socket.assigns.proposed_content
    derived_title = Sections.title_from_blocks(proposed_content)
    current_title = Sections.section_title(proposal.section)

    proposed_title =
      if derived_title && derived_title != current_title, do: derived_title, else: nil

    attrs = %{
      proposed_title: proposed_title,
      proposed_content: proposed_content
    }

    actor = socket.assigns.current_scope.user
    community = socket.assigns.community
    is_moderator = CommunityManager.moderator?(actor, community)

    case Update.call(proposal, attrs, actor, community, is_moderator) do
      {:ok, _proposal} ->
        {:noreply,
         socket
         |> put_flash(:info, "Proposal updated.")
         |> push_navigate(
           to:
             ~p"/c/#{socket.assigns.community.name}/#{socket.assigns.page.slug}/proposals/#{proposal.id}"
         )}

      {:error, :not_pending} ->
        {:noreply, put_flash(socket, :error, "This proposal can no longer be edited.")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update proposal.")}
    end
  end

  defp save_page_proposal(socket, proposal) do
    attrs = %{
      proposed_title: socket.assigns.title,
      proposed_slug: socket.assigns.slug,
      proposed_content: socket.assigns.proposed_content,
      collection_id: socket.assigns.collection_id
    }

    actor = socket.assigns.current_scope.user
    community = socket.assigns.community
    is_moderator = CommunityManager.moderator?(actor, community)

    case Update.call(proposal, attrs, actor, community, is_moderator) do
      {:ok, _proposal} ->
        {:noreply,
         socket
         |> put_flash(:info, "Proposal updated.")
         |> push_navigate(
           to: ~p"/c/#{socket.assigns.community.name}/page-proposals/#{proposal.id}"
         )}

      {:error, :not_pending} ->
        {:noreply, put_flash(socket, :error, "This proposal can no longer be edited.")}

      {:error, changeset} ->
        errors =
          changeset
          |> Ecto.Changeset.traverse_errors(fn {msg, _opts} -> msg end)
          |> Enum.map_join(", ", fn {field, msgs} -> "#{field} #{Enum.join(msgs, ", ")}" end)

        {:noreply, put_flash(socket, :error, "Failed to save: #{errors}")}
    end
  end

  defp parse_collection_id(""), do: nil
  defp parse_collection_id(nil), do: nil

  defp parse_collection_id(id) do
    case Integer.parse(id) do
      {int, _} -> int
      :error -> nil
    end
  end

  defp cancel_path(assigns) do
    if assigns.is_page_proposal do
      ~p"/c/#{assigns.community.name}/page-proposals/#{assigns.proposal.id}"
    else
      ~p"/c/#{assigns.community.name}/#{assigns.page.slug}/proposals/#{assigns.proposal.id}"
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%!-- Sticky top bar --%>
    <div class="sticky top-0 z-10 border-b border-base-300 bg-base-100/95 backdrop-blur-sm">
      <div class="max-w-3xl mx-auto px-8 flex items-center justify-between h-14">
        <div class="flex items-center gap-3 min-w-0">
          <.link
            navigate={cancel_path(assigns)}
            class="text-base-content/40 hover:text-base-content transition shrink-0"
          >
            <.icon name="hero-arrow-left" class="size-4" />
          </.link>
          <div class="min-w-0">
            <h1 class="font-bold text-sm truncate">Edit Proposal</h1>
            <p class="text-xs text-base-content/50 truncate">
              {if @is_page_proposal,
                do: @community.name,
                else: "#{Sections.section_title(@proposal.section)} · #{@page.title}"}
            </p>
          </div>
        </div>
        <div class="flex items-center gap-2 shrink-0">
          <.link navigate={cancel_path(assigns)} class="btn btn-ghost btn-sm rounded-full">
            <.icon name="hero-x-mark" class="size-3.5" /> Cancel
          </.link>
          <button
            phx-click="save-proposal"
            phx-disable-with="Saving..."
            disabled={@is_page_proposal && (@title == "" || @slug == "")}
            class="btn btn-primary btn-sm rounded-full"
          >
            <.icon name="hero-check" class="size-3.5" /> Save Changes
          </button>
        </div>
      </div>
    </div>

    <div class="max-w-3xl mx-auto py-8 px-8">
      <%!-- Page proposal metadata --%>
      <div :if={@is_page_proposal} class="border border-base-300 rounded-xl p-6 mb-8 bg-base-200/30">
        <.section_label class="mb-4">Page Details</.section_label>

        <div class="space-y-4">
          <div class="fieldset">
            <label>
              <span class="label mb-1">Title</span>
              <input
                type="text"
                value={@title}
                phx-keyup="validate"
                phx-debounce="300"
                maxlength="255"
                name="title"
                placeholder="Page title"
                class="w-full input rounded-full focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary"
                autocomplete="off"
              />
            </label>
          </div>

          <div class="fieldset">
            <label>
              <span class="label mb-1">Slug</span>
              <input
                type="text"
                value={@slug}
                readonly
                class="w-full input rounded-full bg-base-200 text-base-content/60"
              />
            </label>
          </div>

          <div :if={@collections != []} class="fieldset">
            <label>
              <span class="label mb-1">Collection (optional)</span>
              <select
                name="collection_id"
                phx-change="validate"
                class="w-full select rounded-full focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary"
              >
                <option value="">None</option>
                <option
                  :for={collection <- @collections}
                  value={collection.id}
                  selected={@collection_id == collection.id}
                >
                  {collection.name}
                </option>
              </select>
            </label>
          </div>
        </div>
      </div>

      <%!-- Editor --%>
      <div :if={@is_page_proposal}>
        <.section_label class="mb-4">Page Content</.section_label>
      </div>

      <div class="prose max-w-none">
        <%!-- Read-only sections before (section proposals only) --%>
        <div :if={!@is_page_proposal && @sections_before != []} class="opacity-50 pointer-events-none">
          <div :for={section <- @sections_before}>
            <.render_block :for={block <- section.content || []} block={block} />
          </div>
        </div>

        <%!-- Editable section --%>
        <div
          :if={!@is_page_proposal}
          id="editable-section"
          phx-hook="ScrollIntoView"
          class="ring-2 ring-primary/30 rounded-lg -mx-4 px-4 py-2 my-4 scroll-mt-20"
        >
          <div
            id="blocknote-editor-edit"
            class="min-h-[200px] flex flex-col"
            phx-hook="BlockEditor"
            phx-update="ignore"
            data-content={Jason.encode!(@proposed_content)}
            data-community={@community.name}
          />
        </div>

        <%!-- Page proposal editor --%>
        <div :if={@is_page_proposal}>
          <div
            id="blocknote-editor-edit"
            class="min-h-[300px] flex flex-col"
            phx-hook="BlockEditor"
            phx-update="ignore"
            data-content={Jason.encode!(@proposed_content)}
            data-community={@community.name}
          />
        </div>

        <%!-- Read-only sections after (section proposals only) --%>
        <div :if={!@is_page_proposal && @sections_after != []} class="opacity-50 pointer-events-none">
          <div :for={section <- @sections_after}>
            <.render_block :for={block <- section.content || []} block={block} />
          </div>
        </div>
      </div>
    </div>
    """
  end
end
