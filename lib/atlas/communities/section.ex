defmodule Atlas.Communities.Section do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sections" do
    field :content, {:array, :map}, default: []
    field :sort_order, :integer

    belongs_to :page, Atlas.Communities.Page
    has_many :proposals, Atlas.Communities.Proposal

    timestamps(type: :utc_datetime)
  end

  def changeset(section, attrs) do
    section
    |> cast(attrs, [:content, :sort_order, :page_id])
    |> validate_required([:sort_order, :page_id])
    |> foreign_key_constraint(:page_id)
  end
end
