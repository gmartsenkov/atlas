defmodule AtlasWeb.CommentsSection do
  @moduledoc false
  use AtlasWeb, :live_component

  @impl true
  def update(%{insert_comment: comment} = _assigns, socket) do
    {:ok,
     socket
     |> stream_insert(:comments, comment, at: 0)
     |> assign(comment_count: socket.assigns.comment_count + 1 + length(comment.replies))}
  end

  def update(%{update_comment: comment}, socket) do
    {:ok, stream_insert(socket, :comments, comment)}
  end

  def update(%{delete_comment: comment}, socket) do
    count = 1 + length(Map.get(comment, :replies, []))

    {:ok,
     socket
     |> stream_delete(:comments, comment)
     |> assign(comment_count: max(socket.assigns.comment_count - count, 0))}
  end

  def update(%{delete_reply: _reply, parent_comment: parent}, socket) do
    {:ok,
     socket
     |> stream_insert(:comments, parent)
     |> assign(comment_count: max(socket.assigns.comment_count - 1, 0))}
  end

  def update(%{append_comments: comments, comments_page: page}, socket) do
    {:ok,
     socket
     |> stream(:comments, comments, at: -1)
     |> assign(comments_page: page)}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:comment_text, fn -> "" end)
      |> assign_new(:reply_text, fn -> "" end)
      |> assign_new(:reply_to, fn -> nil end)
      |> assign_new(:comments_page, fn -> nil end)

    comments = Map.get(assigns, :comments, [])

    socket =
      if Map.get(assigns, :threaded, false) do
        socket
        |> stream(:comments, comments, reset: true)
        |> assign(comment_count: count_comments_threaded(comments))
      else
        assign(socket, comment_count: length(comments))
      end

    {:ok, socket}
  end

  defp count_comments_threaded(comments) do
    Enum.reduce(comments, 0, fn c, acc ->
      acc + 1 + length(Map.get(c, :replies, []))
    end)
  end

  @impl true
  def handle_event("update-text", %{"value" => value}, socket) do
    {:noreply, assign(socket, comment_text: value)}
  end

  def handle_event("add-comment", params, socket) do
    body =
      case params do
        %{"comment" => value} -> String.trim(value)
        _ -> String.trim(socket.assigns.comment_text)
      end

    if body != "" do
      send(self(), {:comments_section, :add_comment, %{body: body}})
      {:noreply, assign(socket, comment_text: "")}
    else
      {:noreply, socket}
    end
  end

  def handle_event("start-reply", %{"id" => id}, socket) do
    case Integer.parse(id) do
      {reply_id, ""} -> {:noreply, assign(socket, reply_to: reply_id, reply_text: "")}
      _ -> {:noreply, socket}
    end
  end

  def handle_event("cancel-reply", _params, socket) do
    {:noreply, assign(socket, reply_to: nil, reply_text: "")}
  end

  def handle_event("update-reply", %{"value" => value}, socket) do
    {:noreply, assign(socket, reply_text: value)}
  end

  def handle_event("add-reply", _params, socket) do
    body = String.trim(socket.assigns.reply_text)

    if body != "" do
      send(
        self(),
        {:comments_section, :add_reply, %{parent_id: socket.assigns.reply_to, body: body}}
      )

      {:noreply, assign(socket, reply_to: nil, reply_text: "")}
    else
      {:noreply, socket}
    end
  end

  def handle_event("delete-comment", %{"id" => id}, socket) do
    send(self(), {:comments_section, :delete_comment, %{comment_id: id}})
    {:noreply, socket}
  end

  def handle_event("load-more-comments", _params, socket) do
    send(self(), {:comments_section, :load_more_comments})
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> assign_new(:threaded, fn -> false end)
      |> assign_new(:is_owner, fn -> false end)
      |> assign_new(:login_path, fn -> nil end)
      |> assign_new(:comments_page, fn -> nil end)

    ~H"""
    <div id={@id} class="mt-12 pt-8 border-t border-base-300 scroll-mt-4">
      <h2 :if={@threaded} class="text-lg font-semibold flex items-center gap-2 mb-6">
        <.icon name="hero-chat-bubble-left-right" class="size-5" /> Comments
        <span :if={@comment_count > 0} class="badge badge-sm rounded-full">
          {@comment_count}
        </span>
      </h2>
      <h3 :if={!@threaded} class="text-lg font-semibold mb-4">Comments</h3>

      <%!-- Comment input --%>
      <%= if @current_user do %>
        <%= if @threaded do %>
          <div class="mb-6">
            <textarea
              phx-keyup="update-text"
              phx-target={@myself}
              phx-debounce="300"
              maxlength="2000"
              placeholder="Add a comment..."
              rows="3"
              class="w-full textarea text-sm rounded-2xl focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary"
            >{@comment_text}</textarea>
            <div class="flex justify-end mt-2">
              <button
                phx-click="add-comment"
                phx-target={@myself}
                phx-disable-with="Posting..."
                class="btn btn-primary btn-sm rounded-full"
              >
                Comment
              </button>
            </div>
          </div>
        <% else %>
          <form phx-submit="add-comment" phx-target={@myself} class="flex gap-2 mb-6">
            <input
              type="text"
              name="comment"
              value={@comment_text}
              phx-keyup="update-text"
              phx-target={@myself}
              phx-debounce="300"
              maxlength="2000"
              placeholder="Add a comment..."
              class="input input-bordered input-sm flex-1 rounded-full focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary"
            />
            <button
              type="submit"
              disabled={@comment_text == ""}
              phx-disable-with="Posting..."
              class="btn btn-primary btn-sm rounded-full"
            >
              Comment
            </button>
          </form>
        <% end %>
      <% else %>
        <div class="text-sm text-base-content/50 mb-6">
          <.link navigate={@login_path || ~p"/users/log-in"} class="link link-primary">Log in</.link>
          to join the discussion.
        </div>
      <% end %>

      <%= if @threaded do %>
        <div
          :if={@comment_count == 0}
          class="text-sm text-base-content/50 mb-6"
        >
          No comments yet. Be the first to start a discussion.
        </div>

        <div
          id={"#{@id}-list"}
          phx-update="stream"
          class={["mb-6", "space-y-4"]}
        >
          <div
            :for={{dom_id, comment} <- @streams.comments}
            id={dom_id}
            class="p-3 rounded-lg bg-base-200/50"
          >
            <div class="flex items-center justify-between mb-1">
              <div class="flex items-center gap-2 text-sm">
                <.link
                  navigate={~p"/u/#{comment.author.nickname}"}
                  class="font-medium hover:underline"
                >
                  {comment.author.nickname}
                </.link>
                <span class="text-base-content/40">
                  {Calendar.strftime(comment.inserted_at, "%b %d, %Y")}
                </span>
              </div>
              <button
                :if={
                  @current_user &&
                    (@current_user.id == comment.author_id || @is_owner)
                }
                phx-click="delete-comment"
                phx-value-id={comment.id}
                phx-target={@myself}
                data-confirm="Delete this comment?"
                class="btn btn-ghost btn-xs"
              >
                <.icon name="hero-trash" class="size-3.5" />
              </button>
            </div>
            <p class="text-sm whitespace-pre-wrap">{comment.body}</p>
            <button
              :if={@current_user}
              phx-click="start-reply"
              phx-value-id={comment.id}
              phx-target={@myself}
              class="text-xs text-base-content/50 hover:text-base-content mt-1 inline-flex items-center gap-1"
            >
              <.icon name="hero-chat-bubble-left" class="size-3" /> Reply
            </button>

            <%!-- Replies --%>
            <div
              :if={comment.replies != []}
              class="mt-3 ml-4 pl-4 border-l-2 border-base-content/20 space-y-3"
            >
              <div
                :for={reply <- comment.replies}
                id={"#{@id}-comment-#{reply.id}"}
                class="p-3 rounded-lg"
              >
                <div class="flex items-center justify-between mb-1">
                  <div class="flex items-center gap-2 text-sm">
                    <.link
                      navigate={~p"/u/#{reply.author.nickname}"}
                      class="font-medium hover:underline"
                    >
                      {reply.author.nickname}
                    </.link>
                    <span class="text-base-content/40">
                      {Calendar.strftime(reply.inserted_at, "%b %d, %Y")}
                    </span>
                  </div>
                  <button
                    :if={
                      @current_user &&
                        (@current_user.id == reply.author_id || @is_owner)
                    }
                    phx-click="delete-comment"
                    phx-value-id={reply.id}
                    phx-target={@myself}
                    data-confirm="Delete this reply?"
                    class="btn btn-ghost btn-xs"
                  >
                    <.icon name="hero-trash" class="size-3.5" />
                  </button>
                </div>
                <p class="text-sm whitespace-pre-wrap">{reply.body}</p>
              </div>
            </div>

            <%!-- Inline reply form --%>
            <div :if={@reply_to == comment.id} class="mt-3 ml-8">
              <textarea
                phx-keyup="update-reply"
                phx-target={@myself}
                phx-debounce="300"
                maxlength="2000"
                placeholder="Write a reply..."
                rows="2"
                class="w-full textarea text-sm rounded-2xl focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary"
              >{@reply_text}</textarea>
              <div class="flex gap-2 mt-2">
                <button
                  phx-click="add-reply"
                  phx-target={@myself}
                  phx-disable-with="Posting..."
                  class="btn btn-primary btn-xs rounded-full"
                >
                  Reply
                </button>
                <button
                  phx-click="cancel-reply"
                  phx-target={@myself}
                  class="btn btn-ghost btn-xs rounded-full"
                >
                  Cancel
                </button>
              </div>
            </div>
          </div>
        </div>

        <.load_more
          :if={@comments_page}
          page={@comments_page}
          on_load_more="load-more-comments"
          phx-target={@myself}
        />
      <% else %>
        <div :if={@comments == []} class="text-sm text-base-content/50 mb-6">
          No comments yet.
        </div>

        <div class="mb-6 space-y-3">
          <%= for comment <- @comments do %>
            <div id={"#{@id}-comment-#{comment.id}"} class="p-3 rounded-lg bg-base-200/50">
              <.user_attribution
                nickname={comment.author.nickname}
                date={comment.inserted_at}
                format="%b %d, %Y %H:%M"
              />
              <p class="text-sm">{comment.body}</p>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end
end
