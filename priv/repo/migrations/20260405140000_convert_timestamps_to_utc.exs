defmodule Atlas.Repo.Migrations.ConvertTimestampsToUtc do
  use Ecto.Migration

  @tables [
    :communities,
    :pages,
    :sections,
    :proposals,
    :proposal_comments,
    :page_stars,
    :page_comments,
    :collections,
    :community_members
  ]

  def change do
    for table <- @tables do
      alter table(table) do
        modify :inserted_at, :utc_datetime, from: :naive_datetime
        modify :updated_at, :utc_datetime, from: :naive_datetime
      end
    end
  end
end
