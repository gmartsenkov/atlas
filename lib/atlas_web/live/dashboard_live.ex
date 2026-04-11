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

    {:ok,
     socket
     |> assign(
       page_title: "Dashboard",
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
       reports_status_counts: reports_status_counts
     )
     |> stream(:community_proposals, community_proposals_page.items)
     |> stream(:user_proposals, user_proposals_page.items)
     |> stream(:reports, reports_page.items)}
  end

  @impl true
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

  defp count_for(status_counts, "all"), do: total_count(status_counts)
  defp count_for(status_counts, status), do: Map.get(status_counts, status, 0)

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-6xl mx-auto overflow-y-auto]">
      <div class="flex items-center gap-4 mb-4">
        <h1 class="text-2xl font-bold">Dashboard</h1>
        <.community_selector
          :if={@selected_community}
          communities={@communities}
          selected={@selected_community}
        />
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 h-[calc(100vh-14rem)]">
        <.community_proposals_section
          :if={@selected_community}
          selected_community={@selected_community}
          status_filter={@community_status_filter}
          status_counts={@community_status_counts}
          proposals_page={@community_proposals_page}
          streams={@streams}
        />

        <.my_proposals_section
          status_filter={@user_status_filter}
          status_counts={@user_status_counts}
          proposals_page={@user_proposals_page}
          streams={@streams}
        />
      </div>

      <.reports_section
        :if={@selected_community}
        selected_community={@selected_community}
        status_filter={@reports_status_filter}
        status_counts={@reports_status_counts}
        reports_page={@reports_page}
        streams={@streams}
      />
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
    <section class="mt-6 pt-6 pb-6 border-t border-base-300">
      <div class="shrink-0">
        <h2 class="text-xl font-bold mb-4">Reports</h2>

        <.status_tabs
          tabs={[{"Pending", "pending"}, {"Resolved", "resolved"}, {"Removed", "removed"}]}
          current={@status_filter}
          counts={@status_counts}
          event="filter-reports"
        />
      </div>

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
            <span :if={@report.page} class="text-xs text-base-content/50">
              <.link
                navigate={~p"/c/#{@community_name}/#{@report.page.slug}"}
                class="hover:underline"
              >
                {@report.page.title}
              </.link>
            </span>
          </div>
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

  defp community_selector(assigns) do
    ~H"""
    <div class="dropdown">
      <div
        tabindex="0"
        role="button"
        class="flex items-center gap-3 px-4 py-2 rounded-xl border border-base-300 bg-base-200/50 hover:bg-base-200 transition cursor-pointer"
      >
        <.community_icon icon={@selected.icon} size={:sm} />
        <span class="font-semibold text-sm">{@selected.name}</span>
        <.icon name="hero-chevron-up-down-mini" class="size-4 text-base-content/40" />
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
