defmodule AtlasWeb.PageLive.Propose do
  use AtlasWeb, :live_view

  alias Atlas.Communities

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

    {:ok,
     assign(socket,
       page_title: "Propose Edit — #{section.title}",
       community: community,
       page: page,
       section: section,
       proposed_content: section.content || [],
       proposed_title: section.title
     )}
  end

  @impl true
  def handle_event("editor-updated", %{"blocks" => blocks}, socket) do
    {:noreply, assign(socket, proposed_content: blocks)}
  end

  def handle_event("update-title", %{"value" => title}, socket) do
    {:noreply, assign(socket, proposed_title: title)}
  end

  def handle_event("submit-proposal", _params, socket) do
    user = socket.assigns.current_scope.user
    section = socket.assigns.section

    attrs = %{
      proposed_title: socket.assigns.proposed_title,
      proposed_content: socket.assigns.proposed_content
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
        Editing section "<span class="font-medium">{@section.title}</span>" of {@page.title}
      </p>

      <div class="space-y-4">
        <div>
          <label class="label text-sm font-medium">Section Title</label>
          <input
            type="text"
            value={@proposed_title}
            phx-keyup="update-title"
            class="input input-bordered w-full"
          />
        </div>

        <div>
          <label class="label text-sm font-medium">Content</label>
          <div class="bg-base-100 rounded-lg border border-base-300">
            <div
              id="blocknote-editor-propose"
              class="min-h-[300px] flex flex-col"
              phx-hook="BlockEditor"
              phx-update="ignore"
              data-content={Jason.encode!(@proposed_content)}
            />
          </div>
        </div>

        <div class="flex justify-end gap-3 pt-4">
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
    </div>
    """
  end
end
