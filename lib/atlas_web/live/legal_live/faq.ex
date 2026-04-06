defmodule AtlasWeb.LegalLive.FAQ do
  use AtlasWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "FAQ")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-3xl">
      <div class="mb-8">
        <h1 class="text-3xl font-bold tracking-tight">Frequently Asked Questions</h1>
        <p class="mt-2 text-base-content/80 text-[15px] leading-relaxed">
          Find answers to common questions about Atlas.
        </p>
      </div>

      <div class="space-y-4">
        <div class="collapse collapse-arrow bg-base-200">
          <input type="radio" name="faq" />
          <div class="collapse-title font-semibold">What is Atlas?</div>
          <div class="collapse-content text-base-content/80 text-[15px]">
            <p>
              Atlas is a collaborative knowledge base where communities can create, edit, and share
              documentation together. Think of it as a wiki built around communities.
            </p>
          </div>
        </div>

        <div class="collapse collapse-arrow bg-base-200">
          <input type="radio" name="faq" />
          <div class="collapse-title font-semibold">How do I create a community?</div>
          <div class="collapse-content text-base-content/80 text-[15px]">
            <p>
              Sign in to your account and click "New Community" from the communities page. Give your
              community a name and description, and you're ready to start adding pages.
            </p>
          </div>
        </div>

        <div class="collapse collapse-arrow bg-base-200">
          <input type="radio" name="faq" />
          <div class="collapse-title font-semibold">How do proposals work?</div>
          <div class="collapse-content text-base-content/80 text-[15px]">
            <p>
              Proposals let community members suggest changes to existing pages or propose new ones.
              Community owners can review, approve, or reject proposals. This keeps content quality
              high while encouraging contributions.
            </p>
          </div>
        </div>

        <div class="collapse collapse-arrow bg-base-200">
          <input type="radio" name="faq" />
          <div class="collapse-title font-semibold">Can I edit pages directly?</div>
          <div class="collapse-content text-base-content/80 text-[15px]">
            <p>
              Community owners and editors can edit pages directly. Other members can suggest changes
              through the proposal system.
            </p>
          </div>
        </div>

        <div class="collapse collapse-arrow bg-base-200">
          <input type="radio" name="faq" />
          <div class="collapse-title font-semibold">Is Atlas free to use?</div>
          <div class="collapse-content text-base-content/80 text-[15px]">
            <p>
              Yes, Atlas is free to use. Create an account and start building your community's
              knowledge base.
            </p>
          </div>
        </div>

        <div class="collapse collapse-arrow bg-base-200">
          <input type="radio" name="faq" />
          <div class="collapse-title font-semibold">How do I delete my account?</div>
          <div class="collapse-content text-base-content/80 text-[15px]">
            <p>
              Go to Settings and scroll to the bottom of the page. You'll find the option to delete
              your account there. This action is permanent and cannot be undone.
            </p>
          </div>
        </div>

        <div class="collapse collapse-arrow bg-base-200">
          <input type="radio" name="faq" />
          <div class="collapse-title font-semibold">I have another question</div>
          <div class="collapse-content text-base-content/80 text-[15px]">
            <p>
              Can't find what you're looking for? Feel free to
              <.link navigate={~p"/contact"} class="link link-primary">contact us</.link>
              and we'll be happy to help.
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
