defmodule AtlasWeb.CommunityLive.About do
  use AtlasWeb, :live_view

  alias Atlas.Communities

  @impl true
  def mount(%{"community_name" => name}, _session, socket) do
    case Communities.get_community_by_name(name) do
      {:error, :not_found} ->
        raise AtlasWeb.NotFoundError

      {:ok, community} ->
        {:ok,
         assign(socket,
           page_title: "About — #{community.name}",
           community: community,
           page_count: length(community.pages),
           report_target: nil
         )}
    end
  end

  @impl true
  def handle_event("report-community", _params, socket) do
    {:noreply, assign(socket, report_target: %{community_id: socket.assigns.community.id})}
  end

  def handle_event("cancel-report", _params, socket) do
    {:noreply, assign(socket, report_target: nil)}
  end

  def handle_event("submit-report", %{"reason" => reason} = params, socket) do
    user =
      case socket.assigns do
        %{current_scope: %{user: %{id: _} = user}} -> user
        _ -> nil
      end

    if user && socket.assigns.report_target do
      attrs =
        socket.assigns.report_target
        |> Map.put(:reason, reason)
        |> Map.put(:details, params["details"])

      case Communities.create_report(user, attrs) do
        {:ok, _report} ->
          {:noreply,
           socket
           |> assign(report_target: nil)
           |> put_flash(:info, "Report submitted. Thank you.")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Could not submit report.")}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto py-8 px-8">
      <.back_link navigate={~p"/c/#{@community.name}"}>{@community.name}</.back_link>

      <%!-- Community Info Card --%>
      <div class="border border-base-300 rounded-xl p-6 mb-8 bg-base-200/30">
        <div class="flex items-start gap-4 mb-4">
          <.community_icon icon={@community.icon} size={:lg} />
          <div>
            <h1 class="text-2xl font-bold">{@community.name}</h1>
            <p :if={@community.description} class="text-base-content/60 mt-1">
              {@community.description}
            </p>
          </div>
        </div>

        <div class="text-sm text-base-content/50 mb-4">
          Created by
          <.link
            navigate={~p"/u/#{@community.owner.nickname}"}
            class="text-base-content/70 font-medium hover:text-base-content transition"
          >
            {@community.owner.nickname}
          </.link>
          ·
          <span title={Calendar.strftime(@community.inserted_at, "%b %d, %Y")}>
            {time_ago(@community.inserted_at)}
          </span>
        </div>

        <div class="flex items-center gap-4 text-sm text-base-content/60">
          <span class="font-medium">{@page_count} pages</span>
          <button
            :if={@current_scope && @current_scope.user}
            phx-click="report-community"
            class="btn btn-ghost btn-xs rounded-full"
            title="Report this community"
          >
            <.icon name="hero-flag" class="size-3.5" /> Report
          </button>
        </div>
      </div>
    </div>

    <div
      :if={@report_target}
      class="modal modal-open"
      id="report-modal"
    >
      <div class="modal-box rounded-2xl border border-base-300">
        <h3 class="text-lg font-bold mb-4">Report Community</h3>
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
              Cancel
            </button>
            <button type="submit" class="btn btn-error rounded-full">
              Submit Report
            </button>
          </div>
        </form>
      </div>
      <div class="modal-backdrop" phx-click="cancel-report"></div>
    </div>
    """
  end
end
