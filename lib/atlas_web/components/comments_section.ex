defmodule AtlasWeb.CommentsSection do
  @moduledoc false
  use AtlasWeb, :live_component

  @impl true
  def update(%{insert_comment: comment}, socket) do
    {:ok,
     socket
     |> assign(comments: [comment | socket.assigns.comments])
     |> assign(comment_count: socket.assigns.comment_count + 1 + length(comment.replies))}
  end

  def update(%{update_comment: comment}, socket) do
    comments =
      Enum.map(socket.assigns.comments, fn c ->
        if c.id == comment.id, do: comment, else: c
      end)

    {:ok, assign(socket, comments: comments)}
  end

  def update(%{delete_comment: comment}, socket) do
    count = 1 + length(Map.get(comment, :replies, []))

    {:ok,
     socket
     |> assign(comments: Enum.reject(socket.assigns.comments, &(&1.id == comment.id)))
     |> assign(comment_count: max(socket.assigns.comment_count - count, 0))}
  end

  def update(%{delete_reply: _reply, parent_comment: parent}, socket) do
    comments =
      Enum.map(socket.assigns.comments, fn c ->
        if c.id == parent.id, do: parent, else: c
      end)

    {:ok,
     socket
     |> assign(comments: comments)
     |> assign(comment_count: max(socket.assigns.comment_count - 1, 0))}
  end

  def update(%{append_comments: new_comments, comments_page: page}, socket) do
    {:ok,
     socket
     |> assign(comments: socket.assigns.comments ++ new_comments)
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
      |> assign_new(:comments, fn -> [] end)

    {:ok, socket}
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

  def handle_event("report-comment", %{"id" => id}, socket) do
    send(self(), {:comments_section, :report_comment, %{comment_id: id}})
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
      |> assign_new(:member_roles, fn -> %{} end)

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

        <div id={"#{@id}-list"} class={["mb-6", "space-y-4"]}>
          <div
            :for={comment <- @comments}
            id={"#{@id}-comment-#{comment.id}"}
            class="p-3 rounded-lg bg-base-200/50"
          >
            <.comment_bubble
              comment={comment}
              can_delete={@current_user && (@current_user.id == comment.author_id || @is_owner)}
              can_report={@current_user && @current_user.id != comment.author_id && !@is_owner}
              role={@member_roles[comment.author_id]}
              myself={@myself}
            >
              <button
                :if={@current_user && !comment.deleted}
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
                class="mt-3 ml-2 pl-4 border-l-2 border-base-content/20 space-y-3"
              >
                <div
                  :for={reply <- comment.replies}
                  id={"#{@id}-reply-#{reply.id}"}
                  class="p-2 rounded-lg"
                >
                  <.comment_bubble
                    comment={reply}
                    can_delete={@current_user && (@current_user.id == reply.author_id || @is_owner)}
                    can_report={@current_user && @current_user.id != reply.author_id && !@is_owner}
                    role={@member_roles[reply.author_id]}
                    myself={@myself}
                    delete_confirm="Delete this reply?"
                    report_title="Report this reply"
                  />
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
            </.comment_bubble>
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
