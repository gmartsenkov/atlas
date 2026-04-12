defmodule AtlasWeb.TimeHelper do
  @moduledoc """
  Helper functions for formatting timestamps as relative time strings.
  """

  @doc """
  Formats a datetime as a human-readable relative time string.

  ## Examples

      iex> time_ago(~U[2026-04-12 12:00:00Z]) # called 30 seconds later
      "just now"

      iex> time_ago(~U[2026-04-12 11:55:00Z]) # called 5 minutes later
      "5m ago"
  """
  def time_ago(%NaiveDateTime{} = naive) do
    naive
    |> DateTime.from_naive!("Etc/UTC")
    |> time_ago()
  end

  def time_ago(%DateTime{} = datetime) do
    diff = DateTime.diff(DateTime.utc_now(), datetime, :second)
    format_diff(max(diff, 0))
  end

  defp format_diff(seconds) when seconds < 60, do: "just now"
  defp format_diff(seconds) when seconds < 3_600, do: "#{div(seconds, 60)}m ago"
  defp format_diff(seconds) when seconds < 86_400, do: "#{div(seconds, 3_600)}h ago"
  defp format_diff(seconds) when seconds < 2_592_000, do: "#{div(seconds, 86_400)}d ago"
  defp format_diff(seconds) when seconds < 31_536_000, do: "#{div(seconds, 2_592_000)}mo ago"
  defp format_diff(seconds), do: "#{div(seconds, 31_536_000)}y ago"
end
