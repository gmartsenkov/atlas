defmodule AtlasWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as tables, forms, and
  inputs. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The foundation for styling is Tailwind CSS, a utility-first CSS framework,
  augmented with daisyUI, a Tailwind CSS plugin that provides UI components
  and themes. Here are useful references:

    * [daisyUI](https://daisyui.com/docs/intro/) - a good place to get
      started and see the available components.

    * [Tailwind CSS](https://tailwindcss.com) - the foundational framework
      we build on. You will use it for layout, sizing, flexbox, grid, and
      spacing.

    * [Heroicons](https://heroicons.com) - see `icon/1` for usage.

    * [Phoenix.Component](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html) -
      the component system used by Phoenix. Some components, such as `<.link>`
      and `<.form>`, are defined there.

  """
  use Phoenix.Component
  use Gettext, backend: AtlasWeb.Gettext

  use Phoenix.VerifiedRoutes,
    endpoint: AtlasWeb.Endpoint,
    router: AtlasWeb.Router,
    statics: AtlasWeb.static_paths()

  alias Phoenix.HTML.Form, as: HtmlForm
  alias Phoenix.LiveView.JS

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      phx-hook="AutoDismiss"
      role="alert"
      class="fixed bottom-6 right-6 z-50 transition-opacity duration-700"
      {@rest}
    >
      <div class={[
        "alert w-80 sm:w-96 max-w-80 sm:max-w-96 text-wrap rounded-xl opacity-90 shadow-lg",
        @kind == :info && "alert-success",
        @kind == :error && "alert-error"
      ]}>
        <.icon :if={@kind == :info} name="hero-check-circle" class="size-5 shrink-0" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle" class="size-5 shrink-0" />
        <div>
          <p :if={@title} class="font-semibold">{@title}</p>
          <p>{msg}</p>
        </div>
        <div class="flex-1" />
        <button type="button" class="group self-start cursor-pointer" aria-label={gettext("close")}>
          <.icon name="hero-x-mark" class="size-5 opacity-40 group-hover:opacity-70" />
        </button>
      </div>
    </div>
    """
  end

  @doc """
  Renders a button with navigation support.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" variant="primary">Send!</.button>
      <.button navigate={~p"/"}>Home</.button>
  """
  attr :rest, :global, include: ~w(href navigate patch method download name value disabled)
  attr :class, :any
  attr :variant, :string, values: ~w(primary)
  slot :inner_block, required: true

  def button(%{rest: rest} = assigns) do
    variants = %{"primary" => "btn-primary", nil => "btn-primary btn-soft"}

    assigns =
      assign_new(assigns, :class, fn ->
        ["btn rounded-full", Map.fetch!(variants, assigns[:variant])]
      end)

    if rest[:href] || rest[:navigate] || rest[:patch] do
      ~H"""
      <.link class={@class} {@rest}>
        {render_slot(@inner_block)}
      </.link>
      """
    else
      ~H"""
      <button class={@class} {@rest}>
        {render_slot(@inner_block)}
      </button>
      """
    end
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information. Unsupported types, such as radio, are best
  written directly in your templates.

  ## Examples

  ```heex
  <.input field={@form[:email]} type="email" />
  <.input name="my-input" errors={["oh no!"]} />
  ```

  ## Select type

  When using `type="select"`, you must pass the `options` and optionally
  a `value` to mark which option should be preselected.

  ```heex
  <.input field={@form[:user_type]} type="select" options={["Admin": "admin", "User": "user"]} />
  ```

  For more information on what kind of data can be passed to `options` see
  [`options_for_select`](https://hexdocs.pm/phoenix_html/Phoenix.HTML.Form.html#options_for_select/2).
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               search select tel text textarea time url week hidden)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :class, :any, default: nil, doc: "the input class to use over defaults"
  attr :error_class, :any, default: nil, doc: "the input error class to use over defaults"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "hidden"} = assigns) do
    ~H"""
    <input type="hidden" id={@id} name={@name} value={@value} {@rest} />
    """
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        HtmlForm.normalize_value(:checkbox, assigns[:value])
      end)

    ~H"""
    <div class="fieldset mb-2">
      <label for={@id}>
        <input
          type="hidden"
          name={@name}
          value="false"
          disabled={@rest[:disabled]}
          form={@rest[:form]}
        />
        <span class="label">
          <input
            type="checkbox"
            id={@id}
            name={@name}
            value="true"
            checked={@checked}
            class={@class || "checkbox checkbox-sm"}
            {@rest}
          />{@label}
        </span>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label for={@id}>
        <span :if={@label} class="label mb-1">{@label}</span>
        <select
          id={@id}
          name={@name}
          class={[
            @class ||
              "w-full select rounded-full focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary",
            @errors != [] && (@error_class || "select-error")
          ]}
          multiple={@multiple}
          {@rest}
        >
          <option :if={@prompt} value="">{@prompt}</option>
          {HtmlForm.options_for_select(@options, @value)}
        </select>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label for={@id}>
        <span :if={@label} class="label mb-1">{@label}</span>
        <textarea
          id={@id}
          name={@name}
          class={[
            @class ||
              "w-full textarea rounded-2xl focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary",
            @errors != [] && (@error_class || "textarea-error")
          ]}
          {@rest}
        >{HtmlForm.normalize_value("textarea", @value)}</textarea>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label for={@id}>
        <span :if={@label} class="label mb-1">{@label}</span>
        <input
          type={@type}
          name={@name}
          id={@id}
          value={HtmlForm.normalize_value(@type, @value)}
          class={[
            @class ||
              "w-full input rounded-full focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary",
            @errors != [] && (@error_class || "input-error")
          ]}
          {@rest}
        />
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # Helper used by inputs to generate form errors
  defp error(assigns) do
    ~H"""
    <p class="mt-1.5 flex gap-2 items-center text-sm text-error">
      <.icon name="hero-exclamation-circle" class="size-5" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", "pb-4"]}>
      <div>
        <h1 class="text-lg font-semibold leading-8">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="text-sm text-base-content/70">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div class="flex-none">{render_slot(@actions)}</div>
    </header>
    """
  end

  @doc """
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id">{user.id}</:col>
        <:col :let={user} label="username">{user.username}</:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <table class="table table-zebra">
      <thead>
        <tr>
          <th :for={col <- @col}>{col[:label]}</th>
          <th :if={@action != []}>
            <span class="sr-only">{gettext("Actions")}</span>
          </th>
        </tr>
      </thead>
      <tbody id={@id} phx-update={is_struct(@rows, Phoenix.LiveView.LiveStream) && "stream"}>
        <tr :for={row <- @rows} id={@row_id && @row_id.(row)}>
          <td
            :for={col <- @col}
            phx-click={@row_click && @row_click.(row)}
            class={@row_click && "hover:cursor-pointer"}
          >
            {render_slot(col, @row_item.(row))}
          </td>
          <td :if={@action != []} class="w-0 font-semibold">
            <div class="flex gap-4">
              <%= for action <- @action do %>
                {render_slot(action, @row_item.(row))}
              <% end %>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title">{@post.title}</:item>
        <:item title="Views">{@post.views}</:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <ul class="list">
      <li :for={item <- @item} class="list-row">
        <div class="list-col-grow">
          <div class="font-bold">{item.title}</div>
          <div>{render_slot(item)}</div>
        </div>
      </li>
    </ul>
    """
  end

  @doc """
  Renders a community icon with a circular container and fallback placeholder.

  ## Examples

      <.community_icon icon={@community.icon} size={:md} />
      <.community_icon icon={nil} size={:sm} />
  """
  attr :icon, :string, default: nil
  attr :size, :atom, default: :md, values: [:sm, :md, :lg]

  def community_icon(assigns) do
    {outer, inner, fallback_icon} =
      case assigns.size do
        :sm -> {"w-7 h-7", "w-5 h-5", "w-3.5 h-3.5"}
        :md -> {"w-10 h-10", "w-7 h-7", "w-5 h-5"}
        :lg -> {"w-12 h-12", "w-8 h-8", "w-6 h-6"}
      end

    assigns = assign(assigns, outer: outer, inner: inner, fallback_icon: fallback_icon)

    ~H"""
    <div
      :if={@icon}
      class={[
        @outer,
        "rounded-full shrink-0 bg-base-content/10 dark:bg-base-content/80 flex items-center justify-center"
      ]}
    >
      <img src={@icon} alt="" class={[@inner, "object-contain"]} />
    </div>
    <div
      :if={!@icon}
      class={[@outer, "rounded-full shrink-0 bg-base-300 flex items-center justify-center"]}
    >
      <.icon name="hero-rectangle-group" class={[@fallback_icon, "text-base-content/40"]} />
    </div>
    """
  end

  @doc """
  Renders a user avatar with a funky gradient default.

  Uses the user's nickname to deterministically generate a unique gradient
  when no avatar image is set.

  ## Examples

      <.user_avatar user={@user} size={:md} />
      <.user_avatar user={@user} size={:sm} />
  """
  attr :user, :map, required: true
  attr :size, :atom, default: :md, values: [:sm, :md, :lg, :xl]

  def user_avatar(assigns) do
    {outer, text_size} =
      case assigns.size do
        :sm -> {"w-6 h-6", "text-[10px]"}
        :md -> {"w-8 h-8", "text-xs"}
        :lg -> {"w-12 h-12", "text-lg"}
        :xl -> {"w-16 h-16", "text-2xl"}
      end

    assigns = assign(assigns, outer: outer, text_size: text_size)

    ~H"""
    <div
      class={[@outer, "rounded-full shrink-0 overflow-hidden"]}
      style={avatar_gradient(@user.nickname)}
    >
      <img :if={@user.avatar_url} src={@user.avatar_url} alt="" class="w-full h-full object-cover" />
      <span
        :if={!@user.avatar_url}
        class={[@outer, @text_size, "flex items-center justify-center font-bold text-white/90"]}
      >
        {String.first(@user.nickname) |> String.upcase()}
      </span>
    </div>
    """
  end

  defp avatar_gradient(nickname) do
    hash = :erlang.phash2(nickname, 360)
    h1 = hash
    h2 = rem(hash + 45 + :erlang.phash2({nickname, :offset}, 90), 360)
    angle = rem(:erlang.phash2({nickname, :angle}, 360), 360)
    "background: linear-gradient(#{angle}deg, hsl(#{h1}, 40%, 65%), hsl(#{h2}, 35%, 55%))"
  end

  @doc """
  Renders a community member role badge.

  ## Examples

      <.role_badge role={:owner} />
      <.role_badge role={:moderator} />
      <.role_badge role={nil} />
  """
  attr :role, :atom, default: nil

  def role_badge(%{role: :owner} = assigns) do
    ~H"""
    <span class="text-[10px] font-medium px-1.5 py-0.5 rounded-full bg-primary/10 text-primary">
      Owner
    </span>
    """
  end

  def role_badge(%{role: :moderator} = assigns) do
    ~H"""
    <span class="text-[10px] font-medium px-1.5 py-0.5 rounded-full bg-secondary/10 text-secondary">
      Mod
    </span>
    """
  end

  def role_badge(assigns), do: ~H""

  @doc """
  Renders a comment bubble with avatar, author info, role badge, action buttons, and body text.

  Used by the comments section for both top-level comments and replies.

  ## Examples

      <.comment_bubble comment={comment} can_delete={true} can_report={false} role={:owner} myself={@myself} />
  """
  attr :comment, :map,
    required: true,
    doc: "comment struct with author, body, inserted_at, deleted, id"

  attr :can_delete, :boolean, default: false
  attr :can_report, :boolean, default: false
  attr :role, :atom, default: nil, doc: "author's community role for badge"
  attr :myself, :any, required: true, doc: "LiveComponent target for events"
  attr :delete_confirm, :string, default: "Delete this comment?"
  attr :report_title, :string, default: "Report this comment"
  attr :score, :integer, default: 0
  attr :user_vote, :integer, default: nil, doc: "current user's vote: 1, -1, or nil"
  attr :can_vote, :boolean, default: false
  slot :inner_block

  def comment_bubble(assigns) do
    ~H"""
    <div class="flex gap-2.5">
      <.link navigate={~p"/u/#{@comment.author.nickname}"} class="shrink-0 mt-0.5">
        <.user_avatar user={@comment.author} size={:sm} />
      </.link>
      <div class="flex-1 min-w-0">
        <div class="flex items-center justify-between mb-1">
          <div class="flex items-center gap-2 text-sm">
            <.link
              navigate={~p"/u/#{@comment.author.nickname}"}
              class="font-medium hover:underline"
            >
              {@comment.author.nickname}
            </.link>
            <.role_badge role={@role} />
            <span class="text-base-content/40">
              {Calendar.strftime(@comment.inserted_at, "%b %d, %Y")}
            </span>
          </div>
          <div :if={!@comment.deleted} class="flex items-center gap-1">
            <button
              :if={@can_report}
              phx-click="report-comment"
              phx-value-id={@comment.id}
              phx-target={@myself}
              title={@report_title}
              class="btn btn-ghost btn-xs"
            >
              <.icon name="hero-flag" class="size-3.5" />
            </button>
            <button
              :if={@can_delete}
              phx-click="delete-comment"
              phx-value-id={@comment.id}
              phx-target={@myself}
              data-confirm={@delete_confirm}
              class="btn btn-ghost btn-xs"
            >
              <.icon name="hero-trash" class="size-3.5" />
            </button>
          </div>
        </div>
        <p :if={@comment.deleted} class="text-sm italic text-base-content/40">
          [Deleted]
        </p>
        <p :if={!@comment.deleted} class="text-sm whitespace-pre-wrap">{@comment.body}</p>
        <div
          :if={!@comment.deleted}
          class="flex items-center gap-1 mt-1.5"
          data-testid={"vote-controls-#{@comment.id}"}
        >
          <button
            :if={@can_vote}
            phx-click="upvote"
            phx-value-id={@comment.id}
            phx-target={@myself}
            class={[
              "btn btn-ghost btn-xs btn-circle",
              @user_vote == 1 && "text-success"
            ]}
            title="Upvote"
            data-testid={"upvote-#{@comment.id}"}
          >
            <.icon name="hero-chevron-up" class="size-3.5" />
          </button>
          <span
            :if={@can_vote || @score != 0}
            class={[
              "text-xs tabular-nums min-w-[1ch] text-center",
              @score > 0 && "text-success font-semibold",
              @score < 0 && "text-error font-semibold",
              @score == 0 && "text-base-content/40"
            ]}
            data-testid={"vote-score-#{@comment.id}"}
          >
            {@score}
          </span>
          <button
            :if={@can_vote}
            phx-click="downvote"
            phx-value-id={@comment.id}
            phx-target={@myself}
            class={[
              "btn btn-ghost btn-xs btn-circle",
              @user_vote == -1 && "text-error"
            ]}
            title="Downvote"
            data-testid={"downvote-#{@comment.id}"}
          >
            <.icon name="hero-chevron-down" class="size-3.5" />
          </button>
        </div>
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  @doc """
  Renders a back navigation link.

  ## Examples

      <.back_link navigate={~p"/c/foo"}>Community</.back_link>
  """
  attr :navigate, :string, required: true
  slot :inner_block, required: true

  def back_link(assigns) do
    ~H"""
    <div class="mb-6">
      <.link
        navigate={@navigate}
        class="text-sm text-base-content/60 hover:text-base-content transition"
      >
        &larr; {render_slot(@inner_block)}
      </.link>
    </div>
    """
  end

  @doc """
  Renders a proposal status badge.

  ## Examples

      <.status_badge status="pending" />
      <.status_badge status="approved" />
  """
  attr :status, :string, required: true

  def status_badge(assigns) do
    ~H"""
    <span class={["badge badge-sm rounded-full", badge_class(@status)]}>
      {@status}
    </span>
    """
  end

  defp badge_class("pending"), do: "badge-warning"
  defp badge_class("approved"), do: "badge-success"
  defp badge_class("rejected"), do: "badge-error"
  defp badge_class(_), do: "badge-ghost"

  @doc """
  Renders a user attribution line ("by username · date").

  ## Examples

      <.user_attribution nickname={@user.nickname} date={@inserted_at} />
  """
  attr :nickname, :string, required: true
  attr :date, :any, required: true
  attr :format, :string, default: "%b %d, %Y"
  attr :prefix, :string, default: "by"

  def user_attribution(assigns) do
    ~H"""
    <div class="text-sm text-base-content/50 mt-1">
      {@prefix}
      <.link navigate={~p"/u/#{@nickname}"} class="hover:text-base-content transition">
        {@nickname}
      </.link>
      · {Calendar.strftime(@date, @format)}
    </div>
    """
  end

  @doc """
  Renders a proposal list item card.

  ## Examples

      <.proposal_card proposal={proposal} href={~p"/proposals/1"} />
      <.proposal_card proposal={proposal} href={~p"/proposals/1"} context="on Page > Section" />
  """
  attr :proposal, :map, required: true
  attr :href, :string, required: true
  attr :context, :string, default: nil

  def proposal_card(assigns) do
    ~H"""
    <div class="p-4 rounded-lg border border-base-300 hover:bg-base-200/50 transition">
      <.link navigate={@href} class="block">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-2">
            <%= if is_nil(@proposal.section_id) do %>
              <.icon name="hero-document-plus" class="size-4 text-primary" />
              <span class="font-medium">New page: "{@proposal.proposed_title}"</span>
            <% else %>
              <span :if={@proposal.proposed_title} class="font-medium">
                Title change: "{@proposal.proposed_title}"
              </span>
              <span :if={!@proposal.proposed_title} class="font-medium text-base-content/60">
                Content edit
              </span>
            <% end %>
            <span :if={@context} class="text-xs text-base-content/40 ml-2">
              {@context}
            </span>
          </div>
          <.status_badge status={@proposal.status} />
        </div>
      </.link>
      <.user_attribution nickname={@proposal.author.nickname} date={@proposal.inserted_at} />
    </div>
    """
  end

  @doc """
  Renders a community card for listing pages.

  ## Examples

      <.community_card community={community} />
  """
  attr :community, :map, required: true

  def community_card(assigns) do
    ~H"""
    <.link
      navigate={~p"/c/#{@community.name}"}
      class="flex items-center gap-4 px-4 py-3 even:bg-base-content/5 hover:bg-base-content/10 transition rounded-lg"
    >
      <.community_icon icon={@community.icon} size={:md} />
      <div class="flex-1 min-w-0">
        <h2 class="font-semibold">{@community.name}</h2>
        <p :if={@community.description} class="text-base-content/60 text-sm truncate">
          {@community.description}
        </p>
      </div>
      <div class="flex items-center gap-1 text-base-content/40 text-xs shrink-0">
        <.icon name="hero-user-group-micro" class="size-3.5" />
        <span>{@community.member_count}</span>
      </div>
    </.link>
    """
  end

  @doc """
  Renders form action buttons (cancel + submit).

  ## Examples

      <.form_actions cancel_href={~p"/"} submit_label="Create" />
  """
  attr :cancel_href, :string, required: true
  attr :submit_label, :string, required: true

  def form_actions(assigns) do
    ~H"""
    <div class="flex justify-end gap-3 pt-4">
      <.link navigate={@cancel_href} class="btn rounded-full">Cancel</.link>
      <button type="submit" class="btn btn-primary rounded-full">{@submit_label}</button>
    </div>
    """
  end

  @doc """
  Renders a "Load more" button for paginated lists.

  Renders nothing when there are no more items. Shows "Load more (N remaining)"
  when there are more items to load.

  ## Examples

      <.load_more page={@communities_page} on_load_more="load-more" />
      <.load_more page={@comments_page} on_load_more="load-more-comments" phx-target={@myself} />
  """
  attr :page, :any, required: true, doc: "an Atlas.Pagination struct"
  attr :on_load_more, :string, required: true, doc: "the event name to send on click"
  attr :rest, :global

  def load_more(assigns) do
    remaining = assigns.page.total - (assigns.page.offset + length(assigns.page.items))
    assigns = assign(assigns, :remaining, remaining)

    ~H"""
    <div :if={@page.has_more} class="flex justify-center mt-6">
      <button phx-click={@on_load_more} {@rest} class="btn btn-ghost btn-sm rounded-full">
        Load more ({@remaining} remaining)
      </button>
    </div>
    """
  end

  @doc """
  Renders an empty state message with optional call-to-action link.

  ## Examples

      <.empty_state href={~p"/new"} link_text="Create one">No items yet.</.empty_state>
      <.empty_state>Nothing here.</.empty_state>
  """
  attr :href, :string, default: nil
  attr :link_text, :string, default: nil
  slot :inner_block, required: true

  def empty_state(assigns) do
    ~H"""
    <div class="text-center py-16 text-base-content/40">
      <p class="text-lg">{render_slot(@inner_block)}</p>
      <.link :if={@href} navigate={@href} class="btn btn-primary btn-sm rounded-full mt-4">
        {@link_text}
      </.link>
    </div>
    """
  end

  @doc """
  Renders a small uppercase section label.

  ## Examples

      <.section_label>Pages</.section_label>
      <.section_label class="mb-2">Title Change</.section_label>
  """
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def section_label(assigns) do
    ~H"""
    <h3 class={["text-[11px] font-semibold text-base-content/40 uppercase tracking-wider", @class]}>
      {render_slot(@inner_block)}
    </h3>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from the `deps/heroicons` directory and bundled within
  your compiled app.css by the plugin in `assets/vendor/heroicons.js`.

  ## Examples

      <.icon name="hero-x-mark" />
      <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :any, default: "size-4"

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  @doc """
  Renders a styled confirmation modal that intercepts `data-confirm` dialogs.

  Render once in the app layout. A JS hook intercepts clicks on `[data-confirm]`
  elements and shows this modal instead of the browser's native `confirm()`.

  ## Examples

      <.confirm_modal />
  """
  def confirm_modal(assigns) do
    ~H"""
    <dialog id="confirm-modal" class="modal" phx-hook="ConfirmModal">
      <div class="modal-box rounded-2xl border border-base-300">
        <p id="confirm-modal-message" class="py-4"></p>
        <div class="modal-action">
          <button id="confirm-modal-cancel" class="btn rounded-full">Cancel</button>
          <button id="confirm-modal-confirm" class="btn btn-primary rounded-full">Confirm</button>
        </div>
      </div>
      <form method="dialog" class="modal-backdrop">
        <button>close</button>
      </form>
    </dialog>
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(AtlasWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(AtlasWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
