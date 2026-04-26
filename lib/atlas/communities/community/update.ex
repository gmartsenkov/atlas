defmodule Atlas.Communities.Community.Update do
  @moduledoc false

  alias Atlas.Authorization
  alias Atlas.Communities.Community
  alias Atlas.Repo

  def call(%Community{} = community, attrs, actor) do
    with :ok <- authorize(actor, community) do
      community
      |> Community.edit_changeset(attrs)
      |> Repo.update()
    end
  end

  defp authorize(actor, community) do
    if Authorization.community_owner?(actor, community) do
      :ok
    else
      {:error, :unauthorized}
    end
  end
end
