defmodule AtlasWeb.CommentsSection do
  @moduledoc false
  use AtlasWeb, :live_component

  alias Atlas.{Authorization, Communities}

  @impl true
  def update(assigns, socket) do
    resource_changed = resource_changed?(assigns, socket)

    socket =
      socket
      |> assign(assigns)
      |> assign_new(:comment_text, fn -> "" end)
      |> assign_new(:reply_text, fn -> "" end)
      |> assign_new(:reply_to, fn -> nil end)
      |> assign_new(:comments, fn -> [] end)
      |> assign_new(:comments_page, fn -> nil end)
      |> assign_new(:comment_count, fn -> 0 end)
      |> assign_new(:is_moderator, fn -> false end)
      |> assign_new(:is_owner, fn -> false end)
      |> assign_new(:member_roles, fn -> %{} end)
      |> assign_new(:reply_counts, fn -> %{} end)
      |> assign_new(:scores, fn -> %{} end)
      |> assign_new(:user_votes, fn -> %{} end)

    socket = if resource_changed, do: load_comments(socket), else: socket

    {:ok, socket}
  end

  defp resource_changed?(assigns, socket) do
    cond do
      not Map.has_key?(socket.assigns, :commentable) ->
        true

      Map.has_key?(assigns, :commentable) ->
        assigns.commentable.id != socket.assigns.commentable.id

      true ->
        false
    end
  end

  defp load_comments(socket) do
    commentable = socket.assigns.commentable
    comments_page = Communities.list_comments(commentable, limit: 20)
    all_ids = collect_comment_ids(comments_page.items)

    assign(socket,
      comments: comments_page.items,
      comments_page: comments_page,
      comment_count: Communities.count_comments(commentable),
      reply_counts: build_reply_counts(comments_page.items),
      scores: Communities.comment_scores(all_ids),
      user_votes: Communities.user_votes(socket.assigns[:current_user], all_ids)
    )
  end

  defp build_reply_counts(comments) do
    Map.new(comments, fn comment ->
      {comment.id, Communities.count_replies(comment.id)}
    end)
  end

  defp collect_comment_ids(comments) do
    Enum.flat_map(comments, fn comment ->
      [comment.id | Enum.map(comment.replies, & &1.id)]
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
      socket = do_add_comment(socket, body)
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
      socket = do_add_reply(socket, socket.assigns.reply_to, body)
      {:noreply, assign(socket, reply_to: nil, reply_text: "")}
    else
      {:noreply, socket}
    end
  end

  def handle_event("delete-comment", %{"id" => id}, socket) do
    {:noreply, do_delete_comment(socket, id)}
  end

  def handle_event("report-comment", %{"id" => id}, socket) do
    send(self(), {:comments_section, :report_comment, %{comment_id: id}})
    {:noreply, socket}
  end

  def handle_event("upvote", %{"id" => id}, socket) do
    {:noreply, do_vote(socket, String.to_integer(id), 1)}
  end

  def handle_event("downvote", %{"id" => id}, socket) do
    {:noreply, do_vote(socket, String.to_integer(id), -1)}
  end

  def handle_event("load-more-replies", %{"id" => id}, socket) do
    case Integer.parse(id) do
      {parent_id, ""} ->
        comment = Enum.find(socket.assigns.comments, &(&1.id == parent_id))

        if comment do
          current_count = length(comment.replies)
          new_replies = Communities.list_replies(parent_id, offset: current_count, limit: 20)
          updated = %{comment | replies: comment.replies ++ new_replies}
          comments = replace_comment(socket.assigns.comments, updated)
          new_ids = Enum.map(new_replies, & &1.id)

          {:noreply,
           assign(socket,
             comments: comments,
             scores: Map.merge(socket.assigns.scores, Communities.comment_scores(new_ids)),
             user_votes:
               Map.merge(
                 socket.assigns.user_votes,
                 Communities.user_votes(socket.assigns[:current_user], new_ids)
               )
           )}
        else
          {:noreply, socket}
        end

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("load-more-comments", _params, socket) do
    %{comments_page: prev, commentable: commentable} = socket.assigns
    new_offset = prev.offset + prev.limit
    comments_page = Communities.list_comments(commentable, limit: 20, offset: new_offset)

    new_reply_counts = build_reply_counts(comments_page.items)
    new_ids = collect_comment_ids(comments_page.items)

    {:noreply,
     assign(socket,
       comments: socket.assigns.comments ++ comments_page.items,
       comments_page: comments_page,
       reply_counts: Map.merge(socket.assigns.reply_counts, new_reply_counts),
       scores: Map.merge(socket.assigns.scores, Communities.comment_scores(new_ids)),
       user_votes:
         Map.merge(
           socket.assigns.user_votes,
           Communities.user_votes(socket.assigns[:current_user], new_ids)
         )
     )}
  end

  defp do_vote(socket, comment_id, value) do
    current_vote = Map.get(socket.assigns.user_votes, comment_id)

    if current_vote == value,
      do: toggle_off_vote(socket, comment_id, value),
      else: cast_vote(socket, comment_id, value, current_vote)
  end

  defp toggle_off_vote(socket, comment_id, value) do
    Communities.unvote_comment(socket.assigns.current_user, comment_id)
    current_score = Map.get(socket.assigns.scores, comment_id, 0)

    assign(socket,
      scores: Map.put(socket.assigns.scores, comment_id, current_score - value),
      user_votes: Map.delete(socket.assigns.user_votes, comment_id)
    )
  end

  defp cast_vote(socket, comment_id, value, current_vote) do
    case Communities.vote_comment(socket.assigns.current_user, comment_id, value) do
      {:ok, _vote} ->
        current_score = Map.get(socket.assigns.scores, comment_id, 0)
        score_delta = if current_vote, do: value - current_vote, else: value

        assign(socket,
          scores: Map.put(socket.assigns.scores, comment_id, current_score + score_delta),
          user_votes: Map.put(socket.assigns.user_votes, comment_id, value)
        )

      {:error, _} ->
        socket
    end
  end

  defp do_add_comment(socket, body) do
    user = socket.assigns.current_user
    commentable = socket.assigns.commentable

    case Communities.add_comment(commentable, user, %{body: body}) do
      {:ok, comment} ->
        {:ok, comment} = Communities.get_comment_with_replies(comment.id)
        new_count = socket.assigns.comment_count + 1
        notify_count_changed(new_count)

        assign(socket,
          comments: [comment | socket.assigns.comments],
          comment_count: new_count,
          reply_counts: Map.put(socket.assigns.reply_counts, comment.id, 0),
          scores: Map.put(socket.assigns.scores, comment.id, 0)
        )

      {:error, _} ->
        socket
    end
  end

  defp do_add_reply(socket, parent_id, body) do
    user = socket.assigns.current_user
    commentable = socket.assigns.commentable

    with {:ok, parent} <- Communities.get_comment(parent_id),
         {:ok, reply} <- Communities.reply_to_comment(commentable, parent, user, %{body: body}) do
      reply = %{reply | author: user}
      comment = Enum.find(socket.assigns.comments, &(&1.id == parent_id))
      updated = %{comment | replies: [reply | comment.replies]}
      new_count = socket.assigns.comment_count + 1
      new_reply_count = Map.get(socket.assigns.reply_counts, parent_id, 0) + 1
      notify_count_changed(new_count)

      assign(socket,
        comments: replace_comment(socket.assigns.comments, updated),
        comment_count: new_count,
        reply_counts: Map.put(socket.assigns.reply_counts, parent_id, new_reply_count),
        scores: Map.put(socket.assigns.scores, reply.id, 0)
      )
    else
      _ -> socket
    end
  end

  defp do_delete_comment(socket, id) do
    user = socket.assigns.current_user
    commentable = socket.assigns.commentable

    with {:ok, comment} <- Communities.get_comment(id),
         true <-
           Authorization.can_delete_comment?(
             user,
             comment,
             commentable,
             socket.assigns.is_moderator
           ) do
      perform_delete(socket, comment)
    else
      _ -> socket
    end
  end

  defp perform_delete(socket, %{parent_id: parent_id} = comment) when not is_nil(parent_id) do
    {:ok, deleted} = Communities.delete_comment(comment)
    parent = Enum.find(socket.assigns.comments, &(&1.id == parent_id))

    updated_replies =
      Enum.map(parent.replies, fn r -> if r.id == deleted.id, do: deleted, else: r end)

    updated = %{parent | replies: updated_replies}

    assign(socket, comments: replace_comment(socket.assigns.comments, updated))
  end

  defp perform_delete(socket, comment) do
    {:ok, deleted} = Communities.delete_comment(comment)
    deleted = %{deleted | replies: comment.replies, author: comment.author}

    assign(socket, comments: replace_comment(socket.assigns.comments, deleted))
  end

  defp replace_comment(comments, updated) do
    Enum.map(comments, fn c -> if c.id == updated.id, do: updated, else: c end)
  end

  defp notify_count_changed(count) do
    send(self(), {:comments_section, :count_changed, count})
  end

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> assign_new(:login_path, fn -> nil end)
      |> assign_new(:comments_page, fn -> nil end)

    ~H"""
    <div id={@id} class="mt-12 pt-8 border-t border-base-300 scroll-mt-4">
      <h2 class="text-lg font-semibold flex items-center gap-2 mb-6">
        <.icon name="hero-chat-bubble-left-right" class="size-5" /> Comments
        <span :if={@comment_count > 0} class="badge badge-sm rounded-full">
          {@comment_count}
        </span>
      </h2>

      <%!-- Comment input --%>
      <%= if @current_user do %>
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
        <div class="text-sm text-base-content/50 mb-6">
          <.link navigate={@login_path || ~p"/users/log-in"} class="link link-primary">Log in</.link>
          to join the discussion.
        </div>
      <% end %>

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
            score={Map.get(@scores, comment.id, 0)}
            user_vote={Map.get(@user_votes, comment.id)}
            can_vote={@current_user != nil && !comment.deleted}
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
              :if={comment.replies != [] || @reply_to == comment.id}
              class="mt-3 ml-2 pl-4 border-l-2 border-base-content/20 space-y-3"
            >
              <%!-- Inline reply form --%>
              <div :if={@reply_to == comment.id}>
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
                  score={Map.get(@scores, reply.id, 0)}
                  user_vote={Map.get(@user_votes, reply.id)}
                  can_vote={@current_user != nil && !reply.deleted}
                />
              </div>
              <button
                :if={length(comment.replies) < Map.get(@reply_counts, comment.id, 0)}
                phx-click="load-more-replies"
                phx-value-id={comment.id}
                phx-target={@myself}
                class="text-xs text-primary hover:text-primary-focus font-medium inline-flex items-center gap-1"
              >
                <.icon name="hero-chevron-down" class="size-3" />
                Show more replies ({Map.get(@reply_counts, comment.id, 0) - length(comment.replies)} remaining)
              </button>
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
    </div>
    """
  end
end
