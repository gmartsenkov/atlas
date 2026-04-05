defmodule AtlasWeb.UserLive.Profile do
  use AtlasWeb, :live_view

  alias Atlas.Accounts

  @impl true
  def mount(%{"nickname" => nickname}, _session, socket) do
    case Accounts.get_user_by_nickname(nickname) do
      {:error, :not_found} ->
        raise AtlasWeb.NotFoundError

      {:ok, user} ->
        {:ok,
         assign(socket,
           page_title: user.nickname,
           profile_user: user
         )}
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
              Joined {account_age(@profile_user.inserted_at)} · {Calendar.strftime(
                @profile_user.inserted_at,
                "%b %d, %Y"
              )}
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
      </div>
    </div>
    """
  end
end
