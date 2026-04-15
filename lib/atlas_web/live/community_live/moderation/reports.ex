defmodule AtlasWeb.CommunityLive.Moderation.Reports do
  @moduledoc false
  use AtlasWeb, :live_view

  alias Atlas.Communities.{Report, ReportsContext}
  import AtlasWeb.CommunityLive.Moderation

  @per_page 20

  @impl true
  def mount(_params, _session, socket) do
    community = socket.assigns.community
    status_counts = ReportsContext.count_community_reports_by_status(community)
    page = ReportsContext.list_community_reports(community, "pending", limit: @per_page)

    {:ok,
     socket
     |> assign(
       page_title: "Reports - #{community.name}",
       report_status_filter: "pending",
       report_status_counts: status_counts,
       reports_page: page
     )
     |> stream(:reports, page.items)}
  end

  @impl true
  def handle_event("filter-reports", %{"status" => status}, socket) do
    community = socket.assigns.community
    page = ReportsContext.list_community_reports(community, status, limit: @per_page)

    {:noreply,
     socket
     |> assign(report_status_filter: status, reports_page: page)
     |> stream(:reports, page.items, reset: true)}
  end

  def handle_event("load-more-reports", _params, socket) do
    %{reports_page: prev, community: community, report_status_filter: status} = socket.assigns
    new_offset = prev.offset + prev.limit

    page =
      ReportsContext.list_community_reports(community, status,
        limit: @per_page,
        offset: new_offset
      )

    {:noreply,
     socket
     |> assign(reports_page: page)
     |> stream(:reports, page.items)}
  end

  def handle_event("resolve", %{"id" => id}, socket) do
    resolver = socket.assigns.current_scope.user

    with {:ok, report} <- ReportsContext.get_report(id),
         {:ok, _} <- ReportsContext.resolve_report(report, resolver) do
      status_counts = ReportsContext.count_community_reports_by_status(socket.assigns.community)

      {:noreply,
       socket
       |> stream_delete(:reports, report)
       |> assign(
         report_status_counts: status_counts,
         pending_reports_count: Map.get(status_counts, "pending", 0)
       )
       |> put_flash(:info, "Report resolved.")}
    else
      _ -> {:noreply, put_flash(socket, :error, "Failed to resolve report.")}
    end
  end

  def handle_event("remove", %{"id" => id}, socket) do
    resolver = socket.assigns.current_scope.user

    with {:ok, report} <- ReportsContext.get_report(id),
         {:ok, _} <- ReportsContext.remove_reported_content(report, resolver) do
      status_counts = ReportsContext.count_community_reports_by_status(socket.assigns.community)

      {:noreply,
       socket
       |> stream_delete(:reports, report)
       |> assign(
         report_status_counts: status_counts,
         pending_reports_count: Map.get(status_counts, "pending", 0)
       )
       |> put_flash(:info, "Content removed.")}
    else
      _ -> {:noreply, put_flash(socket, :error, "Failed to remove content.")}
    end
  end

  defp count_for(status_counts, status), do: Map.get(status_counts, status, 0)

  defp report_type_icon(:comment), do: "hero-chat-bubble-left"
  defp report_type_icon(:page), do: "hero-document-text"
  defp report_type_icon(_), do: "hero-flag"

  defp report_target(report) do
    case Report.report_type(report) do
      :comment -> report.comment && report.comment.body
      :page -> report.page && report.page.title
      _ -> nil
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.mod_layout
      community={@community}
      live_action={:reports}
      is_owner={@is_owner}
      pending_count={@pending_count}
      pending_reports_count={@pending_reports_count}
      moderated_communities={@moderated_communities}
    >
      <div class="max-w-3xl mx-auto">
        <h1 class="text-2xl font-bold mb-4">Reports</h1>

        <.status_tabs
          tabs={[{"Pending", "pending"}, {"Resolved", "resolved"}, {"Removed", "removed"}]}
          current={@report_status_filter}
          counts={@report_status_counts}
          event="filter-reports"
        />

        <div :if={@reports_page.total == 0} class="text-base-content/50 py-8 text-center">
          No reports found.
        </div>

        <div id="mod-reports-list" phx-update="stream" class="space-y-2">
          <div :for={{dom_id, report} <- @streams.reports} id={dom_id}>
            <.report_card
              report={report}
              pending={@report_status_filter == "pending"}
            />
          </div>
        </div>

        <.load_more page={@reports_page} on_load_more="load-more-reports" />
      </div>
    </.mod_layout>
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

  attr :report, :map, required: true
  attr :pending, :boolean, default: false

  defp report_card(assigns) do
    type = Report.report_type(assigns.report)
    assigns = assign(assigns, :type, type)

    ~H"""
    <div class="p-4 rounded-lg border border-base-300 hover:bg-base-200/50 transition">
      <div class="flex items-center justify-between mb-2">
        <div class="flex items-center gap-2">
          <.icon name={report_type_icon(@type)} class="size-4 text-base-content/50" />
          <span class="text-xs font-medium uppercase tracking-wide text-base-content/50">
            {Report.type_label(@report)}
          </span>
          <span class="badge badge-sm badge-outline rounded-full">
            {Report.reason_label(@report.reason)}
          </span>
          <.status_badge status={@report.status} />
        </div>
      </div>

      <div :if={report_target(@report)} class="text-sm mb-2 line-clamp-2">
        {report_target(@report)}
      </div>

      <div :if={@report.details} class="text-sm text-base-content/60 mb-2 line-clamp-2">
        {@report.details}
      </div>

      <.user_attribution
        nickname={@report.reporter.nickname}
        date={@report.inserted_at}
        prefix="reported by"
      />

      <div :if={@pending} class="flex gap-2 mt-3">
        <button
          phx-click="resolve"
          phx-value-id={@report.id}
          class="btn btn-sm btn-success btn-outline rounded-full"
        >
          <.icon name="hero-check" class="size-4" /> Resolve
        </button>
        <button
          phx-click="remove"
          phx-value-id={@report.id}
          data-confirm="Remove this content? This action cannot be undone."
          class="btn btn-sm btn-error btn-outline rounded-full"
        >
          <.icon name="hero-trash" class="size-4" /> Remove
        </button>
      </div>
    </div>
    """
  end
end
