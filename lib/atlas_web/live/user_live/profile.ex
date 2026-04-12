defmodule AtlasWeb.UserLive.Profile do
  use AtlasWeb, :live_view

  alias Atlas.Accounts
  alias Atlas.Communities

  @impl true
  def mount(%{"nickname" => nickname}, _session, socket) do
    case Accounts.get_user_by_nickname(nickname) do
      {:error, :not_found} ->
        raise AtlasWeb.NotFoundError

      {:ok, user} ->
        {:ok,
         assign(socket,
           page_title: user.nickname,
           profile_user: user,
           report_target: nil
         )}
    end
  end

  @impl true
  def handle_event("report-user", _params, socket) do
    {:noreply, assign(socket, report_target: %{reported_user_id: socket.assigns.profile_user.id})}
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

  defp account_age(inserted_at) do
    days = Date.diff(Date.utc_today(), DateTime.to_date(inserted_at))

    cond do
      days < 1 -> "today"
      days == 1 -> "1 day ago"
      days < 30 -> "#{days} days ago"
      days < 365 -> "#{div(days, 30)} months ago"
      true -> "#{div(days, 365)} years ago"
    end
  end

  defp own_profile?(assigns) do
    case assigns do
      %{current_scope: %{user: %{id: id}}, profile_user: %{id: id}} -> true
      _ -> false
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto py-12 px-8">
      <div class="border border-base-300 rounded-xl p-8 bg-base-200/30">
        <div class="flex items-center gap-4 mb-6">
          <.user_avatar user={@profile_user} size={:xl} />
          <div>
            <h1 class="text-2xl font-bold">{@profile_user.nickname}</h1>
            <p class="text-base-content/50 text-sm">
              Joined {account_age(@profile_user.inserted_at)} ·
              <span title={Calendar.strftime(@profile_user.inserted_at, "%b %d, %Y")}>
                {time_ago(@profile_user.inserted_at)}
              </span>
            </p>
          </div>
        </div>

        <div :if={@profile_user.owned_communities != []} class="mt-6">
          <h2 class="text-sm font-semibold text-base-content/50 uppercase tracking-wider mb-3">
            Communities
          </h2>
          <div class="space-y-2">
            <.link
              :for={community <- @profile_user.owned_communities}
              navigate={~p"/c/#{community.name}"}
              class="flex items-center gap-3 p-3 rounded-lg hover:bg-base-content/5 transition"
            >
              <.community_icon icon={community.icon} size={:sm} />
              <span class="font-medium">{community.name}</span>
            </.link>
          </div>
        </div>

        <div :if={@current_scope && @current_scope.user && !own_profile?(assigns)} class="mt-6">
          <button
            phx-click="report-user"
            class="btn btn-ghost btn-xs rounded-full"
            title="Report this user"
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
        <h3 class="text-lg font-bold mb-4">Report User</h3>
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
