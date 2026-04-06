defmodule AtlasWeb.LegalLive.Contact do
  use AtlasWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Contact Us", subject: "", body: "")}
  end

  @impl true
  def handle_event("update", %{"subject" => subject, "body" => body}, socket) do
    {:noreply, assign(socket, subject: subject, body: body)}
  end

  defp mailto_href(subject, body) do
    params =
      URI.encode_query(%{"subject" => subject, "body" => body})

    "mailto:contact@atlas.wiki?#{params}"
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-3xl">
      <div class="mb-8">
        <h1 class="text-3xl font-bold tracking-tight">Contact Us</h1>
        <p class="mt-2 text-base-content/80 text-[15px] leading-relaxed">
          Have a question, feedback, or need help? Fill out the form below and we'll open your email
          client with your message ready to send.
        </p>
      </div>

      <form phx-change="update" class="space-y-4">
        <div>
          <label for="subject" class="label text-sm font-medium">Subject</label>
          <input
            type="text"
            id="subject"
            name="subject"
            value={@subject}
            placeholder="What is this about?"
            class="input input-bordered w-full focus:input-primary focus:ring-0 focus:outline-none"
          />
        </div>
        <div>
          <label for="body" class="label text-sm font-medium">Message</label>
          <textarea
            id="body"
            name="body"
            rows="6"
            placeholder="Write your message here..."
            class="textarea textarea-bordered w-full focus:textarea-primary focus:ring-0 focus:outline-none"
          >{@body}</textarea>
        </div>
        <div>
          <a href={mailto_href(@subject, @body)} class="btn btn-primary rounded-full">
            <.icon name="hero-envelope" class="size-5" /> Send
          </a>
        </div>
      </form>
    </div>
    """
  end
end
