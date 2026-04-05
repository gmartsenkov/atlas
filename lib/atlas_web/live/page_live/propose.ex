defmodule AtlasWeb.PageLive.Propose do
  use AtlasWeb, :live_view

  alias Atlas.Communities
  import AtlasWeb.BlockRenderer

  @impl true
  def mount(
        %{
          "community_name" => community_name,
          "page_slug" => page_slug,
          "section_id" => section_id
        },
        _session,
        socket
      ) do
    with {:ok, community} <- Communities.get_community_by_name(community_name),
         {:ok, page} <- Communities.get_page_by_slugs(community_name, page_slug),
         {section_id_int, ""} <- Integer.parse(section_id),
         {:ok, section} <- Communities.get_section(section_id_int),
         true <- section.page_id == page.id do
      if community.suggestions_enabled do
        all_sections = Communities.list_sections(page.id)

        sections_before = Enum.filter(all_sections, &(&1.sort_order < section.sort_order))
        sections_after = Enum.filter(all_sections, &(&1.sort_order > section.sort_order))

        {:ok,
         assign(socket,
           page_title: "Propose Edit — #{Communities.section_title(section)}",
           community: community,
           page: page,
           section: section,
           sections_before: sections_before,
           sections_after: sections_after,
           proposed_content: section.content || []
         )}
      else
        {:ok,
         socket
         |> put_flash(:error, "Suggestions are disabled for this community.")
         |> push_navigate(to: ~p"/c/#{community.name}/#{page.slug}")}
      end
    else
      {:error, :not_found} -> raise AtlasWeb.NotFoundError
      :error -> raise AtlasWeb.NotFoundError
      false -> raise AtlasWeb.NotFoundError
    end
  end

  @impl true
  def handle_event("editor-updated", %{"blocks" => blocks}, socket) do
    {:noreply, assign(socket, proposed_content: blocks)}
  end

  def handle_event("submit-proposal", _params, socket) do
    user = socket.assigns.current_scope.user
    section = socket.assigns.section
    proposed_content = socket.assigns.proposed_content

    derived_title = Communities.title_from_blocks(proposed_content)
    current_title = Communities.section_title(section)

    proposed_title =
      if derived_title && derived_title != current_title, do: derived_title, else: nil

    attrs = %{
      proposed_title: proposed_title,
      proposed_content: proposed_content
    }

    case Communities.create_proposal(section, user, attrs) do
      {:ok, _proposal} ->
        {:noreply,
         socket
         |> put_flash(:info, "Proposal submitted!")
         |> push_navigate(to: ~p"/c/#{socket.assigns.community.name}/#{socket.assigns.page.slug}")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to submit proposal")}
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
            navigate={~p"/c/#{@community.name}/#{@page.slug}"}
            class="text-base-content/40 hover:text-base-content transition shrink-0"
          >
            <.icon name="hero-arrow-left" class="size-4" />
          </.link>
          <div class="min-w-0">
            <h1 class="font-bold text-sm truncate">Propose Edit</h1>
            <p class="text-xs text-base-content/50 truncate">
              {Communities.section_title(@section)} · {@page.title}
            </p>
          </div>
        </div>
        <div class="flex items-center gap-2 shrink-0">
          <.link
            navigate={~p"/c/#{@community.name}/#{@page.slug}"}
            class="btn btn-ghost btn-sm rounded-full"
          >
            Cancel
          </.link>
          <button phx-click="submit-proposal" class="btn btn-primary btn-sm rounded-full">
            Submit Proposal
          </button>
        </div>
      </div>
    </div>

    <div class="max-w-3xl mx-auto py-8 px-8">
      <div class="prose max-w-none">
        <%!-- Read-only sections before --%>
        <div :if={@sections_before != []} class="opacity-50 pointer-events-none">
          <div :for={section <- @sections_before}>
            <.render_block :for={block <- section.content || []} block={block} />
          </div>
        </div>

        <%!-- Editable target section --%>
        <div
          id="editable-section"
          phx-hook="ScrollIntoView"
          class="ring-2 ring-primary/30 rounded-lg -mx-4 px-4 py-2 my-4 scroll-mt-20"
        >
          <div
            id="blocknote-editor-propose"
            class="min-h-[200px] flex flex-col"
            phx-hook="BlockEditor"
            phx-update="ignore"
            data-content={Jason.encode!(@proposed_content)}
          />
        </div>

        <%!-- Read-only sections after --%>
        <div :if={@sections_after != []} class="opacity-50 pointer-events-none">
          <div :for={section <- @sections_after}>
            <.render_block :for={block <- section.content || []} block={block} />
          </div>
        </div>
      </div>
    </div>
    """
  end
end
