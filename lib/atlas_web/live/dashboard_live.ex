defmodule AtlasWeb.DashboardLive do
  use AtlasWeb, :live_view

  alias Atlas.Communities
  alias Atlas.Communities.{Proposal, Report}
  import Atlas.Communities, only: [section_title: 1]

  @per_page 20

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    communities = Communities.list_user_moderated_communities(user)

    selected =
      case communities do
        [first | _] -> first
        [] -> nil
      end

    {community_proposals_page, community_status_counts} =
      if selected do
        page = Communities.list_community_proposals(selected, "pending", limit: @per_page)
        counts = Communities.count_community_proposals_by_status(selected)
        {page, counts}
      else
        {%Atlas.Pagination{}, %{}}
      end

    user_proposals_page = Communities.list_user_proposals(user, "all", limit: @per_page)
    user_status_counts = Communities.count_user_proposals_by_status(user)

    {reports_page, reports_status_counts} =
      if selected do
        rp = Communities.list_community_reports(selected, "pending", limit: @per_page)
        rc = Communities.count_community_reports_by_status(selected)
        {rp, rc}
      else
        {%Atlas.Pagination{}, %{}}
      end

    active_tab = if communities != [], do: "moderation", else: "my_proposals"

    {:ok,
     socket
     |> assign(
       page_title: "Dashboard",
       active_tab: active_tab,
       communities: communities,
       selected_community: selected,
       community_status_filter: "pending",
       community_proposals_page: community_proposals_page,
       community_status_counts: community_status_counts,
       user_status_filter: "all",
       user_proposals_page: user_proposals_page,
       user_status_counts: user_status_counts,
       reports_status_filter: "pending",
       reports_page: reports_page,
       reports_status_counts: reports_status_counts,
       preview_comment: nil
     )
     |> stream(:community_proposals, community_proposals_page.items)
     |> stream(:user_proposals, user_proposals_page.items)
     |> stream(:reports, reports_page.items)}
  end

  @impl true
  def handle_event("switch-tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_event("select-community", %{"community_id" => id}, socket) do
    selected = Enum.find(socket.assigns.communities, &(to_string(&1.id) == id))

    if selected do
      page = Communities.list_community_proposals(selected, "pending", limit: @per_page)
      counts = Communities.count_community_proposals_by_status(selected)
      reports_page = Communities.list_community_reports(selected, "pending", limit: @per_page)
      reports_counts = Communities.count_community_reports_by_status(selected)

      {:noreply,
       socket
       |> assign(
         active_tab: "moderation",
         selected_community: selected,
         community_status_filter: "pending",
         community_proposals_page: page,
         community_status_counts: counts,
         reports_status_filter: "pending",
         reports_page: reports_page,
         reports_status_counts: reports_counts
       )
       |> stream(:community_proposals, page.items, reset: true)
       |> stream(:reports, reports_page.items, reset: true)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("filter-community-proposals", %{"status" => status}, socket) do
    community = socket.assigns.selected_community
    page = Communities.list_community_proposals(community, status, limit: @per_page)

    {:noreply,
     socket
     |> assign(community_status_filter: status, community_proposals_page: page)
     |> stream(:community_proposals, page.items, reset: true)}
  end

  def handle_event("load-more-community-proposals", _params, socket) do
    %{
      community_proposals_page: prev,
      selected_community: community,
      community_status_filter: status
    } =
      socket.assigns

    new_offset = prev.offset + prev.limit

    page =
      Communities.list_community_proposals(community, status,
        limit: @per_page,
        offset: new_offset
      )

    {:noreply,
     socket
     |> assign(community_proposals_page: page)
     |> stream(:community_proposals, page.items)}
  end

  def handle_event("filter-user-proposals", %{"status" => status}, socket) do
    user = socket.assigns.current_scope.user
    page = Communities.list_user_proposals(user, status, limit: @per_page)

    {:noreply,
     socket
     |> assign(user_status_filter: status, user_proposals_page: page)
     |> stream(:user_proposals, page.items, reset: true)}
  end

  def handle_event("load-more-user-proposals", _params, socket) do
    %{user_proposals_page: prev, user_status_filter: status} = socket.assigns
    user = socket.assigns.current_scope.user
    new_offset = prev.offset + prev.limit
    page = Communities.list_user_proposals(user, status, limit: @per_page, offset: new_offset)

    {:noreply,
     socket
     |> assign(user_proposals_page: page)
     |> stream(:user_proposals, page.items)}
  end

  def handle_event("filter-reports", %{"status" => status}, socket) do
    community = socket.assigns.selected_community
    page = Communities.list_community_reports(community, status, limit: @per_page)

    {:noreply,
     socket
     |> assign(reports_status_filter: status, reports_page: page)
     |> stream(:reports, page.items, reset: true)}
  end

  def handle_event("load-more-reports", _params, socket) do
    %{reports_page: prev, selected_community: community, reports_status_filter: status} =
      socket.assigns

    new_offset = prev.offset + prev.limit

    page =
      Communities.list_community_reports(community, status,
        limit: @per_page,
        offset: new_offset
      )

    {:noreply,
     socket
     |> assign(reports_page: page)
     |> stream(:reports, page.items)}
  end

  def handle_event("resolve-report", %{"id" => id}, socket) do
    user = socket.assigns.current_scope.user

    with {:ok, report} <- Communities.get_report(id),
         {:ok, updated} <- Communities.resolve_report(report, user) do
      community = socket.assigns.selected_community
      counts = Communities.count_community_reports_by_status(community)

      {:noreply,
       socket
       |> assign(reports_status_counts: counts)
       |> stream_delete(:reports, updated)}
    else
      _ -> {:noreply, socket}
    end
  end

  def handle_event("remove-reported-content", %{"id" => id}, socket) do
    user = socket.assigns.current_scope.user

    with {:ok, report} <- Communities.get_report(id),
         {:ok, updated} <- Communities.remove_reported_content(report, user) do
      community = socket.assigns.selected_community
      counts = Communities.count_community_reports_by_status(community)

      {:noreply,
       socket
       |> assign(reports_status_counts: counts)
       |> stream_delete(:reports, updated)}
    else
      _ -> {:noreply, socket}
    end
  end

  def handle_event("preview-comment", %{"id" => id}, socket) do
    with {:ok, report} <- Communities.get_report(id),
         comment when not is_nil(comment) <- report.page_comment do
      {:noreply, assign(socket, preview_comment: comment)}
    else
      _ -> {:noreply, socket}
    end
  end

  def handle_event("close-preview", _params, socket) do
    {:noreply, assign(socket, preview_comment: nil)}
  end

  def handle_event("redact-comment", _params, socket) do
    comment = socket.assigns.preview_comment

    case Communities.redact_page_comment(comment) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(preview_comment: nil)
         |> put_flash(:info, "Comment deleted.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not delete comment.")}
    end
  end

  defp proposal_href(proposal, community_name) do
    if Proposal.new_page_proposal?(proposal) do
      ~p"/c/#{community_name}/page-proposals/#{proposal.id}"
    else
      page_slug = proposal.section.page.slug
      ~p"/c/#{community_name}/#{page_slug}/proposals/#{proposal.id}"
    end
  end

  defp community_name_for(proposal) do
    if Proposal.new_page_proposal?(proposal) do
      proposal.community.name
    else
      case proposal.section.page do
        %{community: %{name: name}} -> name
        page -> page.community.name
      end
    end
  end

  defp proposal_context(proposal) do
    if Proposal.new_page_proposal?(proposal) do
      "New page proposal"
    else
      "on #{proposal.section.page.title} \u203A #{section_title(proposal.section)}"
    end
  end

  defp total_count(status_counts) do
    status_counts |> Map.values() |> Enum.sum()
  end

  defp moderation_count(assigns) do
    total_count(assigns.community_status_counts) + total_count(assigns.reports_status_counts)
  end

  defp count_for(status_counts, "all"), do: total_count(status_counts)
  defp count_for(status_counts, status), do: Map.get(status_counts, status, 0)

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-6xl mx-auto">
      <h1 class="text-2xl font-bold mb-4">Dashboard</h1>

      <div class="flex gap-1 mb-6">
        <.moderation_tab
          :if={@selected_community}
          active={@active_tab == "moderation"}
          communities={@communities}
          selected={@selected_community}
          count={moderation_count(assigns)}
        />
        <button
          phx-click="switch-tab"
          phx-value-tab="my_proposals"
          class={[
            "px-4 py-2 rounded-full text-sm font-medium transition",
            if(@active_tab == "my_proposals",
              do: "bg-base-content/10 text-base-content",
              else: "text-base-content/50 hover:bg-base-content/5 hover:text-base-content"
            )
          ]}
        >
          My Proposals
          <span class="badge badge-sm badge-ghost rounded-full">
            {total_count(@user_status_counts)}
          </span>
        </button>
      </div>

      <%!-- Moderation tab --%>
      <div
        :if={@selected_community}
        class={[@active_tab != "moderation" && "hidden"]}
      >
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 h-[calc(100vh-16rem)]">
          <.reports_section
            selected_community={@selected_community}
            status_filter={@reports_status_filter}
            status_counts={@reports_status_counts}
            reports_page={@reports_page}
            streams={@streams}
          />

          <.community_proposals_section
            selected_community={@selected_community}
            status_filter={@community_status_filter}
            status_counts={@community_status_counts}
            proposals_page={@community_proposals_page}
            streams={@streams}
          />
        </div>
      </div>

      <%!-- My Proposals tab --%>
      <div class={["h-[calc(100vh-16rem)]", @active_tab != "my_proposals" && "hidden"]}>
        <.my_proposals_section
          status_filter={@user_status_filter}
          status_counts={@user_status_counts}
          proposals_page={@user_proposals_page}
          streams={@streams}
        />
      </div>
    </div>

    <div
      :if={@preview_comment}
      class="modal modal-open"
      id="comment-preview-modal"
      phx-click-away="close-preview"
    >
      <div class="modal-box rounded-2xl border border-base-300">
        <h3 class="text-lg font-bold mb-4">Reported Comment</h3>
        <div class="flex items-start gap-3">
          <.user_avatar user={@preview_comment.author} size={:sm} />
          <div class="flex-1 min-w-0">
            <span class="text-sm font-medium">{@preview_comment.author.nickname}</span>
            <p class="text-sm whitespace-pre-wrap mt-1">{@preview_comment.body}</p>
          </div>
        </div>
        <div :if={@preview_comment.deleted} class="mt-3">
          <span class="badge badge-sm badge-error badge-outline rounded-full">Deleted</span>
        </div>
        <div class="modal-action">
          <button class="btn rounded-full" phx-click="close-preview">Close</button>
          <button
            :if={!@preview_comment.deleted}
            class="btn btn-error rounded-full"
            phx-click="redact-comment"
            data-confirm="Are you sure you want to delete this comment?"
          >
            Delete comment
          </button>
        </div>
      </div>
      <div class="modal-backdrop" phx-click="close-preview"></div>
    </div>
    """
  end

  defp community_proposals_section(assigns) do
    ~H"""
    <section class="flex flex-col min-h-0">
      <div class="shrink-0">
        <h2 class="text-xl font-bold mb-4">Community Proposals</h2>

        <.status_tabs
          tabs={[{"Pending", "pending"}, {"Approved", "approved"}, {"Rejected", "rejected"}]}
          current={@status_filter}
          counts={@status_counts}
          event="filter-community-proposals"
        />
      </div>

      <div class="overflow-y-auto min-h-0 flex-1">
        <div :if={@proposals_page.total == 0} class="text-base-content/50 py-4">
          No proposals found.
        </div>

        <div id="community-proposals-list" phx-update="stream" class="space-y-2">
          <div :for={{dom_id, proposal} <- @streams.community_proposals} id={dom_id}>
            <.proposal_card
              proposal={proposal}
              href={proposal_href(proposal, @selected_community.name)}
              context={proposal_context(proposal)}
            />
          </div>
        </div>

        <.load_more page={@proposals_page} on_load_more="load-more-community-proposals" />
      </div>
    </section>
    """
  end

  defp my_proposals_section(assigns) do
    ~H"""
    <section class="flex flex-col min-h-0">
      <div class="shrink-0">
        <h2 class="text-xl font-bold mb-4">My Proposals</h2>

        <.status_tabs
          tabs={[
            {"All", "all"},
            {"Pending", "pending"},
            {"Approved", "approved"},
            {"Rejected", "rejected"}
          ]}
          current={@status_filter}
          counts={@status_counts}
          event="filter-user-proposals"
        />
      </div>

      <div class="overflow-y-auto min-h-0 flex-1">
        <div :if={@proposals_page.total == 0} class="text-base-content/50 py-4">
          No proposals found.
        </div>

        <div id="user-proposals-list" phx-update="stream" class="space-y-2">
          <div :for={{dom_id, proposal} <- @streams.user_proposals} id={dom_id}>
            <.proposal_card
              proposal={proposal}
              href={proposal_href(proposal, community_name_for(proposal))}
              context={proposal_context(proposal)}
            />
          </div>
        </div>

        <.load_more page={@proposals_page} on_load_more="load-more-user-proposals" />
      </div>
    </section>
    """
  end

  defp reports_section(assigns) do
    ~H"""
    <section class="flex flex-col min-h-0">
      <div class="shrink-0">
        <h2 class="text-xl font-bold mb-4">Reports</h2>

        <.status_tabs
          tabs={[{"Pending", "pending"}, {"Resolved", "resolved"}, {"Removed", "removed"}]}
          current={@status_filter}
          counts={@status_counts}
          event="filter-reports"
        />
      </div>

      <div class="overflow-y-auto min-h-0 flex-1">
        <div :if={@reports_page.total == 0} class="text-base-content/50 py-4">
          No reports found.
        </div>

        <div id="reports-list" phx-update="stream" class="space-y-2">
          <div :for={{dom_id, report} <- @streams.reports} id={dom_id}>
            <.report_card
              report={report}
              community_name={@selected_community.name}
              status_filter={@status_filter}
            />
          </div>
        </div>

        <.load_more page={@reports_page} on_load_more="load-more-reports" />
      </div>
    </section>
    """
  end

  defp report_card(assigns) do
    ~H"""
    <div class="p-4 rounded-lg border border-base-300 bg-base-200/30">
      <div class="flex items-start justify-between gap-4">
        <div class="flex-1 min-w-0">
          <div class="flex items-center gap-2 mb-1">
            <span class="badge badge-sm badge-outline rounded-full">
              {Report.reason_label(@report.reason)}
            </span>
            <span class="badge badge-sm badge-ghost rounded-full">{Report.type_label(@report)}</span>
            <.link
              :if={@report.page}
              navigate={~p"/c/#{@community_name}/#{@report.page.slug}"}
              class="text-sm font-medium hover:underline inline-flex items-center gap-1"
            >
              <.icon name="hero-document-text-mini" class="size-4" />
              {@report.page.title}
            </.link>
          </div>
          <button
            :if={@report.page_comment}
            phx-click="preview-comment"
            phx-value-id={@report.id}
            class="flex items-center gap-1 text-sm text-base-content/70 hover:text-base-content cursor-pointer mb-1"
          >
            <.icon name="hero-chat-bubble-left-mini" class="size-4 shrink-0" />
            <span class="line-clamp-1 text-left">{@report.page_comment.body}</span>
          </button>
          <p :if={@report.details} class="text-sm text-base-content/70 mb-1 line-clamp-2">
            {@report.details}
          </p>
          <.user_attribution
            :if={@report.reporter}
            nickname={@report.reporter.nickname}
            date={@report.inserted_at}
            prefix="Reported by"
          />
        </div>
        <div :if={@status_filter == "pending"} class="flex items-center gap-2 shrink-0">
          <button
            phx-click="resolve-report"
            phx-value-id={@report.id}
            class="btn btn-ghost btn-xs rounded-full"
          >
            Dismiss
          </button>
          <button
            phx-click="remove-reported-content"
            phx-value-id={@report.id}
            class="btn btn-error btn-xs rounded-full"
          >
            Remove
          </button>
        </div>
      </div>
    </div>
    """
  end

  defp moderation_tab(assigns) do
    ~H"""
    <div class="dropdown">
      <div
        tabindex="0"
        role="button"
        phx-click="switch-tab"
        phx-value-tab="moderation"
        class={[
          "flex items-center gap-2 px-4 py-2 rounded-full text-sm font-medium transition cursor-pointer",
          if(@active,
            do: "bg-base-content/10 text-base-content",
            else: "text-base-content/50 hover:bg-base-content/5 hover:text-base-content"
          )
        ]}
      >
        <.community_icon icon={@selected.icon} size={:sm} />
        <span>{@selected.name}</span>
        <.icon name="hero-chevron-down-mini" class="size-3.5 opacity-50" />
        <span class="badge badge-sm badge-ghost rounded-full">{@count}</span>
      </div>
      <ul
        tabindex="0"
        class="dropdown-content menu border border-base-300 bg-base-100 rounded-xl z-10 w-64 p-2 shadow-lg mt-1"
      >
        <li :for={c <- @communities}>
          <button
            phx-click="select-community"
            phx-value-community_id={c.id}
            onclick="document.activeElement?.blur()"
            class={["flex items-center gap-3", c.id == @selected.id && "active"]}
          >
            <.community_icon icon={c.icon} size={:sm} />
            <span class="text-sm">{c.name}</span>
          </button>
        </li>
      </ul>
    </div>
    """
  end

  defp status_tabs(assigns) do
    ~H"""
    <div class="flex gap-1 mb-6">
      <button
        :for={{label, value} <- @tabs}
        phx-click={@event}
        phx-value-status={value}
        class={[
          "px-3 py-1.5 rounded-full text-sm font-medium transition",
          if(@current == value,
            do: "bg-base-content/10 text-base-content",
            else: "text-base-content/50 hover:bg-base-content/5 hover:text-base-content"
          )
        ]}
      >
        {label}
        <span class="text-xs ml-1 opacity-60">
          ({count_for(@counts, value)})
        </span>
      </button>
    </div>
    """
  end
end
