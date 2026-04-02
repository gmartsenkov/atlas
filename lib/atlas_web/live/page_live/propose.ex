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
    community = Communities.get_community_by_name!(community_name)
    page = Communities.get_page_by_slugs!(community_name, page_slug)
    section = Communities.get_section!(String.to_integer(section_id))
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

    proposed_title =
      current_title = Communities.section_title(section)
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
         |> push_navigate(
           to: ~p"/c/#{socket.assigns.community.name}/#{socket.assigns.page.slug}"
         )}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to submit proposal")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto py-8 px-8">
      <div class="mb-6">
        <.link
          navigate={~p"/c/#{@community.name}/#{@page.slug}"}
          class="text-sm text-base-content/60 hover:text-base-content"
        >
          &larr; {@page.title}
        </.link>
      </div>

      <h1 class="text-2xl font-bold mb-2">Propose Edit</h1>
      <p class="text-base-content/60 mb-6">
        Editing section "<span class="font-medium">{Communities.section_title(@section)}</span>" of {@page.title}
      </p>

      <div class="prose max-w-none">
        <%!-- Read-only sections before --%>
        <div :if={@sections_before != []} class="opacity-50 pointer-events-none">
          <div :for={section <- @sections_before}>
            <.render_block :for={block <- section.content || []} block={block} />
          </div>
        </div>

        <%!-- Editable target section --%>
        <div class="ring-2 ring-primary/30 rounded-lg -mx-4 px-4 py-2 my-4">
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

      <div class="flex justify-end gap-3 pt-6">
        <.link
          navigate={~p"/c/#{@community.name}/#{@page.slug}"}
          class="btn btn-ghost rounded-full"
        >
          Cancel
        </.link>
        <button phx-click="submit-proposal" class="btn btn-primary rounded-full">
          Submit Proposal
        </button>
      </div>
    </div>
    """
  end
end
