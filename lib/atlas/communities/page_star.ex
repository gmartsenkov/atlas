defmodule Atlas.Communities.PageStar do
  use Ecto.Schema
  import Ecto.Changeset

  schema "page_stars" do
    belongs_to :user, Atlas.Accounts.User
    belongs_to :page, Atlas.Communities.Page

    timestamps(type: :utc_datetime)
  end

  def changeset(star, attrs) do
    star
    |> cast(attrs, [:user_id, :page_id])
    |> validate_required([:user_id, :page_id])
    |> unique_constraint([:user_id, :page_id])
  end
end
