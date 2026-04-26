defmodule AtlasWeb.UserLive.Registration do
  use AtlasWeb, :live_view

  alias Atlas.Accounts
  alias Atlas.Accounts.User
  alias Atlas.Accounts.User.Register

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <div class="text-center">
        <.header>
          Register for an account
          <:subtitle>
            Already registered?
            <.link navigate={~p"/users/log-in"} class="font-semibold text-brand hover:underline">
              Log in
            </.link>
            to your account now.
          </:subtitle>
        </.header>
      </div>

      <.form for={@form} id="registration_form" phx-submit="save" phx-change="validate">
        <.input
          field={@form[:email]}
          type="email"
          label="Email"
          autocomplete="username"
          spellcheck="false"
          required
          phx-mounted={JS.focus()}
        />
        <.input
          field={@form[:nickname]}
          type="text"
          label="Nickname"
          autocomplete="off"
          spellcheck="false"
          required
        />

        <div class="fieldset mb-2">
          <label for={@form[:terms_accepted].id}>
            <input
              type="hidden"
              name={@form[:terms_accepted].name}
              value="false"
            />
            <span class="label">
              <input
                type="checkbox"
                id={@form[:terms_accepted].id}
                name={@form[:terms_accepted].name}
                value="true"
                checked={
                  @form[:terms_accepted].value == true or @form[:terms_accepted].value == "true"
                }
                class="checkbox checkbox-sm"
              /> I agree to the
              <.link navigate={~p"/terms"} class="link link-primary">Terms of Service</.link>
              and <.link navigate={~p"/privacy"} class="link link-primary">Privacy Policy</.link>
            </span>
          </label>
          <p
            :for={err <- @form[:terms_accepted].errors}
            class="mt-1.5 flex gap-2 items-center text-sm text-error"
          >
            <.icon name="hero-exclamation-circle" class="size-4 shrink-0" />
            {translate_error(err)}
          </p>
        </div>

        <.button phx-disable-with="Creating account..." class="btn btn-primary w-full rounded-full">
          Create an account
        </.button>
      </.form>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket)
      when not is_nil(user) do
    {:ok, redirect(socket, to: AtlasWeb.UserAuth.signed_in_path(socket))}
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{}, %{}, validate_unique: false)

    {:ok, assign_form(socket, changeset), temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    case Register.call(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_login_instructions(
            user,
            &url(~p"/users/log-in/#{&1}")
          )

        {:noreply,
         socket
         |> put_flash(
           :info,
           "An email was sent to #{user.email}, please access it to confirm your account."
         )
         |> push_navigate(to: ~p"/users/log-in")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params, validate_unique: false)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end
end
