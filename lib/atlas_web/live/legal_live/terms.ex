defmodule AtlasWeb.LegalLive.Terms do
  use AtlasWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Terms of Service")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-3xl">
      <div class="mb-8">
        <h1 class="text-3xl font-bold tracking-tight">Terms of Service</h1>
        <p class="mt-2 text-sm text-base-content/50">Last updated: April 6, 2026</p>
      </div>

      <div class="space-y-8 text-base-content/80 text-[15px] leading-relaxed">
        <section>
          <h2 class="text-lg font-semibold text-base-content mb-2">1. Acceptance of Terms</h2>
          <p>
            By accessing or using Atlas ("Service"), you agree to be bound by these Terms of Service
            ("Terms"). If you do not agree to these Terms, you may not use the Service.
          </p>
        </section>

        <section>
          <h2 class="text-lg font-semibold text-base-content mb-2">2. Description of Service</h2>
          <p>
            Atlas is a collaborative knowledge-base platform that allows users to create communities,
            write and edit pages, and share documentation. We reserve the right to modify, suspend, or
            discontinue the Service at any time.
          </p>
        </section>

        <section>
          <h2 class="text-lg font-semibold text-base-content mb-2">3. User Accounts</h2>
          <p>
            To use certain features, you must register for an account. You agree to provide accurate
            information and keep your account credentials secure. You are responsible for all activity
            under your account.
          </p>
        </section>

        <section>
          <h2 class="text-lg font-semibold text-base-content mb-2">4. User Content</h2>
          <p>
            You retain ownership of content you create on Atlas. By posting content, you grant Atlas a
            non-exclusive, worldwide, royalty-free license to use, display, and distribute your content
            in connection with the Service. You must not post content that is unlawful, harmful,
            threatening, abusive, defamatory, or otherwise objectionable.
          </p>
        </section>

        <section>
          <h2 class="text-lg font-semibold text-base-content mb-2">5. Acceptable Use</h2>
          <p class="mb-2">You agree not to:</p>
          <ul class="list-disc pl-6 space-y-1">
            <li>Use the Service for any unlawful purpose</li>
            <li>Attempt to gain unauthorized access to any part of the Service</li>
            <li>Interfere with or disrupt the Service or its infrastructure</li>
            <li>Upload malicious code, spam, or harmful content</li>
            <li>Impersonate any person or entity</li>
            <li>Harvest or collect user information without consent</li>
          </ul>
        </section>

        <section>
          <h2 class="text-lg font-semibold text-base-content mb-2">6. Intellectual Property</h2>
          <p>
            The Service and its original content (excluding user content) are and remain the property of
            Atlas. Our trademarks and trade dress may not be used without prior written consent.
          </p>
        </section>

        <section>
          <h2 class="text-lg font-semibold text-base-content mb-2">7. Termination</h2>
          <p>
            We may terminate or suspend your account at any time, without prior notice, for conduct that
            we determine violates these Terms or is harmful to the Service or other users.
          </p>
        </section>

        <section>
          <h2 class="text-lg font-semibold text-base-content mb-2">8. Disclaimer of Warranties</h2>
          <p>
            The Service is provided "as is" and "as available" without warranties of any kind, either
            express or implied. We do not warrant that the Service will be uninterrupted, secure, or
            error-free.
          </p>
        </section>

        <section>
          <h2 class="text-lg font-semibold text-base-content mb-2">9. Limitation of Liability</h2>
          <p>
            To the fullest extent permitted by law, Atlas shall not be liable for any indirect,
            incidental, special, consequential, or punitive damages arising from your use of the Service.
          </p>
        </section>

        <section>
          <h2 class="text-lg font-semibold text-base-content mb-2">10. Changes to Terms</h2>
          <p>
            We may update these Terms from time to time. We will notify users of material changes by
            posting the updated Terms on this page with a new effective date. Continued use of the
            Service after changes constitutes acceptance of the revised Terms.
          </p>
        </section>

        <section>
          <h2 class="text-lg font-semibold text-base-content mb-2">11. Contact</h2>
          <p>
            If you have questions about these Terms, please contact us through the platform.
          </p>
        </section>
      </div>
    </div>
    """
  end
end
