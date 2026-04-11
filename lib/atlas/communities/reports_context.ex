defmodule Atlas.Communities.ReportsContext do
  @moduledoc false
  import Ecto.Query

  alias Atlas.Communities.Report
  alias Atlas.Pagination
  alias Atlas.Repo

  def create_report(reporter, attrs) do
    %Report{}
    |> Report.changeset(Map.put(attrs, :reporter_id, reporter.id))
    |> Repo.insert()
  end

  @valid_statuses ~w(pending resolved removed)

  def list_community_reports(community, status \\ "pending", opts \\ []) do
    status = if status in @valid_statuses, do: status, else: "pending"

    from(r in Report,
      where:
        r.community_id == ^community.id and r.status == ^status and
          (not is_nil(r.page_id) or not is_nil(r.page_comment_id)),
      order_by: [desc: r.inserted_at],
      preload: [:reporter, :page, [page_comment: :author], :resolved_by]
    )
    |> Pagination.paginate(opts)
  end

  def count_community_reports_by_status(community) do
    from(r in Report,
      where:
        r.community_id == ^community.id and
          (not is_nil(r.page_id) or not is_nil(r.page_comment_id)),
      group_by: r.status,
      select: {r.status, count(r.id)}
    )
    |> Repo.all()
    |> Map.new()
  end

  def get_report(id) do
    case Repo.get(Report, id) do
      nil ->
        {:error, :not_found}

      report ->
        {:ok,
         Repo.preload(report, [
           :reporter,
           :page,
           {:page_comment, :author},
           :community,
           :reported_user,
           :resolved_by
         ])}
    end
  end

  def resolve_report(report, resolver) do
    report
    |> Report.resolve_changeset(%{
      status: "resolved",
      resolved_by_id: resolver.id,
      resolved_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
    |> Repo.update()
  end

  def remove_reported_content(report, resolver) do
    report
    |> Report.resolve_changeset(%{
      status: "removed",
      resolved_by_id: resolver.id,
      resolved_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
    |> Repo.update()
  end
end
