defmodule Atlas.Communities.Moderation.RestrictUser do
  @moduledoc false

  alias Atlas.Communities.{CommunityManager, Moderation, RestrictionsContext}
  alias Atlas.Repo

  def call(community, target_user, actor, attrs) do
    with :ok <- Moderation.authorize_moderator(actor, community) do
      Ecto.Multi.new()
      |> Ecto.Multi.run(:restriction, fn _repo, _changes ->
        RestrictionsContext.create_restriction(community, target_user, actor, attrs)
      end)
      |> Ecto.Multi.run(:remove_membership, fn _repo, _changes ->
        CommunityManager.remove_member(community, target_user)
        {:ok, :removed}
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{restriction: restriction}} -> {:ok, restriction}
        {:error, :restriction, changeset, _} -> {:error, changeset}
      end
    end
  end
end
