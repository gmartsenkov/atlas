defmodule AtlasWeb.UserLive.Settings do
  use AtlasWeb, :live_view

  on_mount {AtlasWeb.UserAuth, :require_sudo_mode}

  alias Atlas.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-xl mx-auto">
      <h1 class="text-3xl font-bold mb-8">Account Settings</h1>

      <div class="flex items-center gap-6">
        <div
          id="avatar-upload"
          phx-hook="LogoUpload"
          class="cursor-pointer group relative"
        >
          <.user_avatar user={@current_user} size={:xl} />
          <div class="absolute inset-0 rounded-full bg-black/50 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
            <.icon name="hero-camera" class="w-6 h-6 text-white" />
          </div>
          <input type="file" accept="image/*" class="hidden" />
        </div>
        <div>
          <p class="font-medium">{@current_user.nickname}</p>
          <p class="text-sm text-base-content/50">Click avatar to upload a new photo</p>
          <button
            :if={@current_user.avatar_url}
            phx-click="remove-avatar"
            class="text-sm text-error hover:underline mt-1"
          >
            Remove avatar
          </button>
        </div>
      </div>

      <div class="mt-12">
        <h2 class="text-xl font-bold mb-4">Email</h2>
        <.form
          for={@email_form}
          id="email_form"
          phx-submit="update_email"
          phx-change="validate_email"
          class="space-y-4"
        >
          <.input
            field={@email_form[:email]}
            type="email"
            label="Email"
            autocomplete="username"
            spellcheck="false"
            required
          />
          <div class="flex justify-end">
            <.button variant="primary" phx-disable-with="Changing...">Change Email</.button>
          </div>
        </.form>
      </div>

      <div class="mt-12">
        <h2 class="text-xl font-bold mb-4">Password</h2>
        <.form
          for={@password_form}
          id="password_form"
          action={~p"/users/update-password"}
          method="post"
          phx-change="validate_password"
          phx-submit="update_password"
          phx-trigger-action={@trigger_submit}
          class="space-y-4"
        >
          <input
            name={@password_form[:email].name}
            type="hidden"
            id="hidden_user_email"
            spellcheck="false"
            value={@current_email}
          />
          <.input
            field={@password_form[:password]}
            type="password"
            label="New password"
            autocomplete="new-password"
            spellcheck="false"
            required
          />
          <.input
            field={@password_form[:password_confirmation]}
            type="password"
            label="Confirm new password"
            autocomplete="new-password"
            spellcheck="false"
          />
          <div class="flex justify-end">
            <.button variant="primary" phx-disable-with="Saving...">Save Password</.button>
          </div>
        </.form>
      </div>

      <div class="mt-12">
        <h2 class="text-xl font-bold mb-4 text-error">Delete Account</h2>
        <div id="delete-account" class="border border-error/30 rounded-lg p-6">
          <p class="text-sm text-base-content/60">
            Permanently delete your account and all associated data. This action cannot be undone.
          </p>
          <.form for={%{}} id="delete_account_form" phx-submit="delete_account" class="mt-4 space-y-4">
            <.input
              name="nickname"
              value={@nickname_confirmation}
              type="text"
              label={"Type your nickname (#{@current_user.nickname}) to confirm"}
              autocomplete="off"
              spellcheck="false"
              required
            />
            <div class="flex justify-end">
              <button
                type="submit"
                class="btn btn-error btn-soft rounded-full"
                phx-disable-with="Deleting..."
              >
                <.icon name="hero-trash" class="size-4" /> Delete My Account
              </button>
            </div>
          </.form>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_scope.user, token) do
        {:ok, _user} ->
          put_flash(socket, :info, "Email changed successfully.")

        {:error, _} ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    email_changeset = Accounts.change_user_email(user, %{}, validate_unique: false)
    password_changeset = Accounts.change_user_password(user, %{}, hash_password: false)

    socket =
      socket
      |> assign(:current_user, user)
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)
      |> assign(:nickname_confirmation, "")

    {:ok, socket}
  end

  @impl true
  def handle_event("logo-uploaded", %{"url" => url}, socket) do
    user = socket.assigns.current_scope.user

    case Accounts.update_user_avatar(user, %{avatar_url: url}) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(:current_user, user)
         |> put_flash(:info, "Avatar updated!")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update avatar.")}
    end
  end

  def handle_event("remove-avatar", _params, socket) do
    user = socket.assigns.current_scope.user

    case Accounts.update_user_avatar(user, %{avatar_url: nil}) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(:current_user, user)
         |> put_flash(:info, "Avatar removed.")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to remove avatar.")}
    end
  end

  def handle_event("delete_account", %{"nickname" => nickname}, socket) do
    user = socket.assigns.current_user

    if nickname == user.nickname do
      {:ok, _user} = Accounts.delete_user(user)

      {:noreply,
       socket
       |> put_flash(:info, "Account deleted.")
       |> redirect(to: ~p"/")}
    else
      {:noreply, put_flash(socket, :error, "Nickname does not match.")}
    end
  end

  def handle_event("validate_email", params, socket) do
    %{"user" => user_params} = params

    email_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_email(user_params, validate_unique: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form)}
  end

  def handle_event("update_email", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_email(user, user_params) do
      %{valid?: true} = changeset ->
        Accounts.deliver_user_update_email_instructions(
          Ecto.Changeset.apply_action!(changeset, :insert),
          user.email,
          &url(~p"/users/settings/confirm-email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info)}

      changeset ->
        {:noreply, assign(socket, :email_form, to_form(changeset, action: :insert))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"user" => user_params} = params

    password_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_password(user_params, hash_password: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form)}
  end

  def handle_event("update_password", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_password(user, user_params) do
      %{valid?: true} = changeset ->
        {:noreply, assign(socket, trigger_submit: true, password_form: to_form(changeset))}

      changeset ->
        {:noreply, assign(socket, password_form: to_form(changeset, action: :insert))}
    end
  end
end
