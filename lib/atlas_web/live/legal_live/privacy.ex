defmodule AtlasWeb.LegalLive.Privacy do
  use AtlasWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Privacy Policy")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-3xl">
      <div class="mb-8">
        <h1 class="text-3xl font-bold tracking-tight">Privacy Policy</h1>
        <p class="mt-2 text-sm text-base-content/50">Last updated: April 6, 2026</p>
      </div>

      <div class="space-y-8 text-base-content/80 text-[15px] leading-relaxed">
        <section>
          <h2 class="text-lg font-semibold text-base-content mb-2">1. Information We Collect</h2>
          <p class="mb-2">We collect the following types of information:</p>
          <ul class="list-disc pl-6 space-y-1">
            <li>
              <strong class="text-base-content">Account information</strong>
              — email address, nickname, and avatar when you register
            </li>
            <li>
              <strong class="text-base-content">Content</strong>
              — pages, comments, proposals, and other content you create on the platform
            </li>
            <li>
              <strong class="text-base-content">Usage data</strong>
              — information about how you interact with the Service, including pages visited and actions taken
            </li>
            <li>
              <strong class="text-base-content">Device information</strong>
              — browser type, operating system, and IP address
            </li>
          </ul>
        </section>

        <section>
          <h2 class="text-lg font-semibold text-base-content mb-2">2. How We Use Your Information</h2>
          <p class="mb-2">We use your information to:</p>
          <ul class="list-disc pl-6 space-y-1">
            <li>Provide and maintain the Service</li>
            <li>Create and manage your account</li>
            <li>Send transactional emails (login links, notifications)</li>
            <li>Improve and personalize the Service</li>
            <li>Protect against fraud and abuse</li>
          </ul>
        </section>

        <section>
          <h2 class="text-lg font-semibold text-base-content mb-2">3. Information Sharing</h2>
          <p class="mb-2">
            We do not sell your personal information. We may share information with third parties only in
            the following circumstances:
          </p>
          <ul class="list-disc pl-6 space-y-1">
            <li>With your consent</li>
            <li>To comply with legal obligations</li>
            <li>To protect our rights, privacy, safety, or property</li>
            <li>
              With service providers who assist in operating the Service (subject to confidentiality agreements)
            </li>
          </ul>
        </section>

        <section>
          <h2 class="text-lg font-semibold text-base-content mb-2">4. Data Retention</h2>
          <p>
            We retain your information for as long as your account is active or as needed to provide the
            Service. You may request deletion of your account and associated data at any time.
          </p>
        </section>

        <section>
          <h2 class="text-lg font-semibold text-base-content mb-2">5. Security</h2>
          <p>
            We implement reasonable security measures to protect your information. However, no method of
            transmission over the Internet is 100% secure, and we cannot guarantee absolute security.
          </p>
        </section>

        <section>
          <h2 class="text-lg font-semibold text-base-content mb-2">6. Cookies</h2>
          <p>
            We use essential cookies to maintain your session and preferences. We do not use third-party
            tracking cookies.
          </p>
        </section>

        <section>
          <h2 class="text-lg font-semibold text-base-content mb-2">7. Your Rights</h2>
          <p class="mb-2">You have the right to:</p>
          <ul class="list-disc pl-6 space-y-1">
            <li>Access your personal information</li>
            <li>Correct inaccurate information</li>
            <li>Delete your account and data</li>
            <li>Export your data</li>
            <li>Object to processing of your information</li>
          </ul>
        </section>

        <section>
          <h2 class="text-lg font-semibold text-base-content mb-2">8. Children's Privacy</h2>
          <p>
            The Service is not intended for children under 13. We do not knowingly collect information
            from children under 13.
          </p>
        </section>

        <section>
          <h2 class="text-lg font-semibold text-base-content mb-2">9. Changes to This Policy</h2>
          <p>
            We may update this Privacy Policy from time to time. We will notify you of material changes
            by posting the updated policy on this page with a new effective date.
          </p>
        </section>

        <section>
          <h2 class="text-lg font-semibold text-base-content mb-2">10. Contact</h2>
          <p>
            If you have questions about this Privacy Policy, please
          <.link navigate={~p"/contact"} class="link link-primary">contact us</.link>.
          </p>
        </section>
      </div>
    </div>
    """
  end
end
