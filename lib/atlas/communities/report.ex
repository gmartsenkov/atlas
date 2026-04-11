defmodule Atlas.Communities.Report do
  use Ecto.Schema
  import Ecto.Changeset

  @reasons ~w(spam harassment misinformation inappropriate copyright other)
  @statuses ~w(pending resolved removed)

  schema "reports" do
    field :reason, :string
    field :details, :string
    field :status, :string, default: "pending"
    field :resolved_at, :utc_datetime

    belongs_to :community, Atlas.Communities.Community
    belongs_to :page, Atlas.Communities.Page
    belongs_to :comment, Atlas.Communities.Comment
    belongs_to :reported_user, Atlas.Accounts.User
    belongs_to :reporter, Atlas.Accounts.User
    belongs_to :resolved_by, Atlas.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(report, attrs) do
    report
    |> cast(attrs, [
      :reason,
      :details,
      :community_id,
      :page_id,
      :comment_id,
      :reported_user_id,
      :reporter_id
    ])
    |> validate_required([:reason, :reporter_id])
    |> validate_inclusion(:reason, @reasons)
    |> validate_length(:details, max: 2000)
    |> foreign_key_constraint(:community_id)
    |> foreign_key_constraint(:page_id)
    |> foreign_key_constraint(:comment_id)
    |> foreign_key_constraint(:reported_user_id)
    |> foreign_key_constraint(:reporter_id)
    |> check_constraint(:reason, name: :valid_reason)
    |> check_constraint(:status, name: :valid_status)
  end

  def resolve_changeset(report, attrs) do
    report
    |> cast(attrs, [:status, :resolved_by_id, :resolved_at])
    |> validate_required([:status, :resolved_by_id, :resolved_at])
    |> validate_inclusion(:status, @statuses)
  end

  def report_type(%__MODULE__{comment_id: id}) when not is_nil(id), do: :comment
  def report_type(%__MODULE__{page_id: id}) when not is_nil(id), do: :page
  def report_type(%__MODULE__{reported_user_id: id}) when not is_nil(id), do: :user
  def report_type(%__MODULE__{}), do: :community

  def reasons, do: @reasons

  def type_label(report) do
    case report_type(report) do
      :comment -> "Comment"
      :page -> "Page"
      :user -> "User"
      :community -> "Community"
    end
  end

  def reason_label(reason) do
    case reason do
      "spam" -> "Spam"
      "harassment" -> "Harassment"
      "misinformation" -> "Misinformation"
      "inappropriate" -> "Inappropriate"
      "copyright" -> "Copyright"
      "other" -> "Other"
      _ -> reason
    end
  end
end
