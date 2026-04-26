defmodule AtlasWeb.CommunityLive.Show do
  use AtlasWeb, :live_view

  alias Atlas.Authorization

  alias Atlas.Communities.Community.{Join, Leave}

  alias Atlas.Communities.{
    CommentsContext,
    CommunityManager,
    PagesContext,
    ReportsContext,
    Sections,
    Stars
  }

  alias Atlas.Communities.Star.Create, as: StarCreate
  alias Atlas.Communities.Star.Delete, as: StarDelete

  import AtlasWeb.BlockRenderer

  @impl true
  def mount(%{"community_name" => name}, _session, socket) do
    case CommunityManager.get_community_by_name(name) do
      {:error, :not_found} ->
        raise AtlasWeb.NotFoundError

      {:ok, community} ->
        current_user = current_user(socket)

        is_member =
          if current_user, do: CommunityManager.member?(current_user, community), else: false

        is_owner = Authorization.community_owner?(current_user, community)
        is_moderator = CommunityManager.moderator?(current_user, community)
        member_roles = CommunityManager.community_member_roles(community)

        suggestions_enabled = community.suggestions_enabled

        {collected_pages, uncollected_pages} =
          group_pages_by_collection(community.pages, community.collections)

        {:ok,
         assign(socket,
           full_bleed: true,
           community: community,
           pages: community.pages,
           collected_pages: collected_pages,
           uncollected_pages: uncollected_pages,
           is_member: is_member,
           is_owner: is_owner,
           is_moderator: is_moderator,
           member_roles: member_roles,
           suggestions_enabled: suggestions_enabled,
           auto_expand_collection_id: nil,
           search_query: "",
           sidebar_open: false,
           report_target: nil
         )}
    end
  end

  defp current_user(socket) do
    case socket.assigns do
      %{current_scope: %{user: %{id: _} = user}} -> user
      _ -> nil
    end
  end

  defp group_pages_by_collection(pages, collections) do
    collected =
      collections
      |> Enum.map(fn collection ->
        collection_pages =
          pages
          |> Enum.filter(&(&1.collection_id == collection.id))
          |> Enum.sort_by(&{&1.sort_order, &1.title})

        {collection, collection_pages}
      end)
      |> Enum.filter(fn {_collection, pages} -> pages != [] end)

    uncollected =
      pages
      |> Enum.filter(&is_nil(&1.collection_id))
      |> Enum.sort_by(&{&1.sort_order, &1.title})

    {collected, uncollected}
  end

  defp assign_page(socket, page, params) do
    is_mod = socket.assigns.is_moderator

    is_page_owner = socket.assigns.is_owner || is_mod

    current_user = current_user(socket)

    is_starred =
      if current_user,
        do: Stars.page_starred?(current_user, page),
        else: false

    star_count = Stars.count_page_stars(page)

    socket =
      socket
      |> assign(
        page_title: "#{page.title} — #{socket.assigns.community.name}",
        current_page: page,
        sections: page.sections,
        headings: Sections.extract_headings(page.sections),
        is_page_owner: is_page_owner,
        is_starred: is_starred,
        star_count: star_count,
        sidebar_open: false,
        comment_count: CommentsContext.count_comments(page)
      )

    case params["scroll_to"] do
      nil -> push_event(socket, "scroll-top", %{})
      id -> push_event(socket, "scroll-to", %{id: id})
    end
  end

  @impl true
  def handle_params(%{"page_slug" => page_slug} = params, _uri, socket) do
    case PagesContext.get_page_by_slugs(socket.assigns.community.name, page_slug) do
      {:error, :not_found} ->
        raise AtlasWeb.NotFoundError

      {:ok, page} ->
        {:noreply,
         socket
         |> assign(auto_expand_collection_id: page.collection_id)
         |> assign_page(page, params)}
    end
  end

  def handle_params(_params, _uri, socket) do
    case socket.assigns.pages do
      [first | _] ->
        {:noreply,
         push_patch(socket,
           to: ~p"/c/#{socket.assigns.community.name}/#{first.slug}",
           replace: true
         )}

      [] ->
        {:noreply,
         assign(socket,
           page_title: socket.assigns.community.name,
           current_page: nil,
           sections: [],
           headings: [],
           is_page_owner: false,
           is_starred: false,
           star_count: 0,
           comment_count: 0
         )}
    end
  end

  defp require_user(socket, fun) do
    case current_user(socket) do
      nil -> {:noreply, socket}
      user -> fun.(user)
    end
  end

  @impl true
  def handle_event("join", _params, socket) do
    require_user(socket, fn user ->
      community = socket.assigns.community

      case Join.call(user, community) do
        {:ok, _} -> {:noreply, assign(socket, is_member: true)}
        {:error, _} -> {:noreply, socket}
      end
    end)
  end

  def handle_event("leave", _params, socket) do
    require_user(socket, fn user ->
      community = socket.assigns.community

      case Leave.call(user, community) do
        :ok ->
          {:noreply, assign(socket, is_member: false)}

        {:error, :owner_cannot_leave} ->
          {:noreply, put_flash(socket, :error, "Community owners cannot leave their community.")}

        {:error, :not_a_member} ->
          {:noreply, socket}
      end
    end)
  end

  def handle_event("star", _params, socket) do
    require_user(socket, fn user ->
      page = socket.assigns.current_page

      case StarCreate.call(user, page) do
        {:ok, _} ->
          {:noreply, assign(socket, is_starred: true, star_count: Stars.count_page_stars(page))}

        {:error, _} ->
          {:noreply, socket}
      end
    end)
  end

  def handle_event("unstar", _params, socket) do
    require_user(socket, fn user ->
      page = socket.assigns.current_page
      StarDelete.call(user, page)

      {:noreply, assign(socket, is_starred: false, star_count: Stars.count_page_stars(page))}
    end)
  end

  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, assign(socket, sidebar_open: !socket.assigns.sidebar_open)}
  end

  def handle_event("scroll-to-comments", _params, socket) do
    {:noreply, push_event(socket, "scroll-to", %{id: "comments"})}
  end

  def handle_event("cancel-report", _params, socket) do
    {:noreply, assign(socket, report_target: nil)}
  end

  def handle_event("report-page", _params, socket) do
    page = socket.assigns.current_page

    {:noreply,
     assign(socket, report_target: %{page_id: page.id, community_id: page.community_id})}
  end

  def handle_event("report-comment", %{"id" => comment_id}, socket) do
    page = socket.assigns.current_page

    {:noreply,
     assign(socket,
       report_target: %{
         page_id: page.id,
         comment_id: comment_id,
         community_id: page.community_id
       }
     )}
  end

  def handle_event("submit-report", %{"reason" => reason} = params, socket) do
    require_user(socket, fn user ->
      case socket.assigns.report_target do
        nil -> {:noreply, socket}
        target -> submit_report(socket, user, target, reason, params["details"])
      end
    end)
  end

  defp submit_report(socket, user, target, reason, details) do
    attrs =
      target
      |> Map.put(:reason, reason)
      |> Map.put(:details, details)

    case ReportsContext.create_report(user, attrs) do
      {:ok, _report} ->
        {:noreply,
         socket
         |> assign(report_target: nil)
         |> put_flash(:info, "Report submitted. Thank you.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not submit report.")}
    end
  end

  @impl true
  def handle_info({:sidebar, :search_changed, query}, socket) do
    {:noreply, assign(socket, search_query: query)}
  end

  def handle_info({:comments_section, :count_changed, count}, socket) do
    {:noreply, assign(socket, comment_count: count)}
  end

  def handle_info({:comments_section, :report_comment, %{comment_id: comment_id}}, socket) do
    page = socket.assigns.current_page

    {:noreply,
     assign(socket,
       report_target: %{
         page_id: page.id,
         comment_id: comment_id,
         community_id: page.community_id
       }
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%!-- Community topbar --%>
    <div class="sticky top-0 z-10 border-b border-base-300 bg-base-200/30 backdrop-blur-sm px-4 sm:px-6">
      <div class="flex items-center justify-between h-14">
        <div class="flex items-center gap-3 min-w-0">
          <button
            phx-click="toggle_sidebar"
            class="text-base-content/40 hover:text-base-content transition shrink-0 lg:hidden"
          >
            <.icon name="hero-bars-3" class="size-5" />
          </button>
          <.community_icon icon={@community.icon} size={:sm} />
          <h2 class="font-bold text-base truncate">{@community.name}</h2>
          <span :if={@community.owner} class="text-xs text-base-content/40 shrink-0 hidden sm:inline">
            by
            <.link
              navigate={~p"/u/#{@community.owner.nickname}"}
              class="hover:text-base-content transition"
            >
              {@community.owner.nickname}
            </.link>
          </span>
        </div>
        <div class="flex items-center gap-2 shrink-0">
          <%!-- Full nav links (md+) --%>
          <.link
            navigate={~p"/c/#{@community.name}/about"}
            class="hidden md:inline-flex btn btn-ghost btn-xs rounded-full"
          >
            <.icon name="hero-information-circle" class="size-3.5" /> About
          </.link>
          <.link
            :if={@current_scope && @current_scope.user && (@is_owner || @is_moderator)}
            navigate={~p"/c/#{@community.name}/collections"}
            class="hidden md:inline-flex btn btn-ghost btn-xs rounded-full"
          >
            <.icon name="hero-folder-plus" class="size-3.5" /> Collections
          </.link>
          <.link
            :if={@current_scope && @current_scope.user && (@is_owner || @is_moderator)}
            navigate={~p"/mod/#{@community.name}"}
            class="hidden md:inline-flex btn btn-ghost btn-xs rounded-full"
          >
            <.icon name="hero-shield-check" class="size-3.5" /> Mod
          </.link>
          <%!-- Overflow menu (small screens) --%>
          <div class="dropdown dropdown-end md:hidden">
            <div tabindex="0" role="button" class="btn btn-ghost btn-xs rounded-full">
              <.icon name="hero-ellipsis-vertical" class="size-4" /> More
            </div>
            <ul
              tabindex="0"
              class="dropdown-content menu bg-base-200 rounded-box z-10 w-44 p-2 shadow-lg mt-1"
            >
              <li>
                <.link navigate={~p"/c/#{@community.name}/about"}>
                  <.icon name="hero-information-circle" class="size-4" /> About
                </.link>
              </li>
              <li :if={@current_scope && @current_scope.user && (@is_owner || @is_moderator)}>
                <.link navigate={~p"/c/#{@community.name}/collections"}>
                  <.icon name="hero-folder-plus" class="size-4" /> Collections
                </.link>
              </li>
              <li :if={@current_scope && @current_scope.user && (@is_owner || @is_moderator)}>
                <.link navigate={~p"/mod/#{@community.name}"}>
                  <.icon name="hero-shield-check" class="size-4" /> Mod
                </.link>
              </li>
            </ul>
          </div>
          <button
            :if={@current_scope && @current_scope.user && !@is_member}
            phx-click="join"
            class="btn btn-primary btn-xs rounded-full"
          >
            <.icon name="hero-user-plus" class="size-3.5" /> Join
          </button>
          <button
            :if={@current_scope && @current_scope.user && @is_member && !@is_owner}
            phx-click="leave"
            data-confirm={
              @is_moderator &&
                "You are a moderator of this community. Are you sure you want to leave?"
            }
            class="btn btn-outline btn-error btn-xs rounded-full"
          >
            <.icon name="hero-arrow-right-start-on-rectangle" class="size-3.5" /> Leave
          </button>
        </div>
      </div>
    </div>

    <div class="flex h-[calc(100vh-4rem-3.5rem)] relative overflow-hidden">
      <%!-- Mobile sidebar backdrop --%>
      <div
        phx-click="toggle_sidebar"
        class={["absolute inset-0 bg-black/30 z-20 lg:hidden", !@sidebar_open && "hidden"]}
      />
      <%!-- Sidebar --%>
      <.live_component
        module={AtlasWeb.CommunitySidebar}
        id="sidebar"
        community={@community}
        collected_pages={@collected_pages}
        uncollected_pages={@uncollected_pages}
        current_page={@current_page}
        headings={@headings}
        is_owner={@is_owner || @is_moderator}
        suggestions_enabled={@suggestions_enabled}
        current_scope={@current_scope}
        sidebar_open={@sidebar_open}
        auto_expand_collection_id={@auto_expand_collection_id}
      />

      <%!-- Main content --%>
      <main id="page-content" phx-hook="ScrollToTarget" class="flex-1 overflow-y-auto">
        <div :if={@current_page} class="max-w-3xl mx-auto py-8 px-8">
          <div class="flex items-center justify-between mb-8">
            <h1 class="text-3xl font-bold">{@current_page.title}</h1>
            <div class="flex items-center gap-2">
              <button
                :if={@current_scope && @current_scope.user && @is_starred}
                phx-click="unstar"
                class="btn btn-ghost btn-sm rounded-full"
              >
                <.icon name="hero-star-solid" class="size-4 text-amber-400" />
                {format_count(@star_count)}
              </button>
              <button
                :if={@current_scope && @current_scope.user && !@is_starred}
                phx-click="star"
                class="btn btn-ghost btn-sm rounded-full"
              >
                <.icon name="hero-star" class="size-4" />
                {format_count(@star_count)}
              </button>
              <span
                :if={!@current_scope || !@current_scope.user}
                class="flex items-center gap-1 text-sm text-base-content/50"
              >
                <.icon name="hero-star" class="size-4" />
                {format_count(@star_count)}
              </span>
              <button phx-click="scroll-to-comments" class="btn btn-ghost btn-sm rounded-full">
                <.icon name="hero-chat-bubble-left" class="size-4" />
                {format_count(@comment_count)}
              </button>
              <button
                :if={@current_scope && @current_scope.user && !@is_page_owner}
                phx-click="report-page"
                class="btn btn-ghost btn-sm rounded-full"
                title="Report this page"
              >
                <.icon name="hero-flag" class="size-4" />
              </button>
              <.link
                :if={@is_page_owner}
                navigate={~p"/c/#{@community.name}/#{@current_page.slug}/edit"}
                class="btn btn-primary btn-sm rounded-full"
              >
                <.icon name="hero-pencil-square" class="size-3.5" /> Edit
              </.link>
            </div>
          </div>

          <div class="prose max-w-none">
            <%= for section <- @sections do %>
              <div id={"section-#{section.id}"} class="scroll-mt-8 relative group">
                <.link
                  :if={
                    @suggestions_enabled && @current_scope && @current_scope.user && !@is_page_owner
                  }
                  navigate={
                    ~p"/c/#{@community.name}/#{@current_page.slug}/sections/#{section.id}/propose"
                  }
                  class="btn btn-ghost btn-xs rounded-full absolute right-0 top-6 opacity-0 group-hover:opacity-100 transition-opacity"
                >
                  <.icon name="hero-pencil-square" class="size-3" /> Propose Edit
                </.link>
                <.render_block
                  :for={block <- section.content || []}
                  block={block}
                  highlight={@search_query}
                />
              </div>
            <% end %>
          </div>

          <div :if={@current_page.owner} class="mt-12 flex items-center gap-3 justify-end">
            <.link navigate={~p"/u/#{@current_page.owner.nickname}"}>
              <.user_avatar user={@current_page.owner} size={:md} />
            </.link>
            <div class="text-sm">
              <span class="text-base-content/50">Created by</span>
              <.link
                navigate={~p"/u/#{@current_page.owner.nickname}"}
                class="font-medium hover:underline ml-1"
              >
                {@current_page.owner.nickname}
              </.link>
              <span
                class="text-base-content/40 ml-1"
                title={Calendar.strftime(@current_page.inserted_at, "%b %d, %Y")}
              >
                · {time_ago(@current_page.inserted_at)}
              </span>
            </div>
          </div>

          <.live_component
            module={AtlasWeb.CommentsSection}
            id="comments"
            commentable={@current_page}
            current_user={@current_scope && @current_scope.user}
            is_owner={@is_page_owner}
            is_moderator={@is_moderator}
            member_roles={@member_roles}
          />
        </div>

        <div :if={!@current_page} class="flex items-center justify-center h-full">
          <.empty_state
            href={~p"/c/#{@community.name}/new"}
            link_text="Create the first page"
          >
            No pages yet.
          </.empty_state>
        </div>
      </main>
    </div>

    <div
      :if={@report_target}
      class="modal modal-open"
      id="report-modal"
      phx-click-away="cancel-report"
    >
      <div class="modal-box rounded-2xl border border-base-300">
        <h3 class="text-lg font-bold mb-4">Report Content</h3>
        <form phx-submit="submit-report" id="report-form">
          <div class="form-control mb-4">
            <label class="label" for="report-reason">
              <span class="label-text font-medium">Reason</span>
            </label>
            <select
              id="report-reason"
              name="reason"
              class="select select-bordered rounded-xl w-full"
              required
            >
              <option value="" disabled selected>Select a reason</option>
              <option value="spam">Spam</option>
              <option value="harassment">Harassment</option>
              <option value="misinformation">Misinformation</option>
              <option value="inappropriate">Inappropriate content</option>
              <option value="copyright">Copyright violation</option>
              <option value="other">Other</option>
            </select>
          </div>
          <div class="form-control mb-4">
            <label class="label" for="report-details">
              <span class="label-text font-medium">Details (optional)</span>
            </label>
            <textarea
              id="report-details"
              name="details"
              maxlength="2000"
              rows="3"
              placeholder="Provide additional context..."
              class="textarea textarea-bordered rounded-xl w-full"
            />
          </div>
          <div class="modal-action">
            <button type="button" class="btn rounded-full" phx-click="cancel-report">
              <.icon name="hero-x-mark" class="size-4" /> Cancel
            </button>
            <button type="submit" class="btn btn-error rounded-full">
              <.icon name="hero-flag" class="size-4" /> Submit Report
            </button>
          </div>
        </form>
      </div>
      <div class="modal-backdrop" phx-click="cancel-report"></div>
    </div>
    """
  end
end
