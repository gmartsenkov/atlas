defmodule AtlasWeb.NumberHelper do
  @moduledoc """
  Helper functions for formatting numbers for display.
  """

  @doc """
  Formats a count for compact display.

  Numbers below 1 000 are returned as-is. Numbers 1 000 and above
  are shown with one decimal place and a "K" suffix (trailing ".0" is dropped).

  ## Examples

      iex> format_count(42)
      "42"

      iex> format_count(999)
      "999"

      iex> format_count(1000)
      "1K"

      iex> format_count(1500)
      "1.5K"

      iex> format_count(20_500)
      "20.5K"

      iex> format_count(-1500)
      "-1.5K"
  """
  def format_count(n) when is_integer(n) and n >= 0 and n < 1_000, do: Integer.to_string(n)

  def format_count(n) when is_integer(n) and n > -1_000 and n < 0, do: Integer.to_string(n)

  def format_count(n) when is_integer(n) and n >= 1_000 do
    tenths = div(n, 100)
    whole = div(tenths, 10)
    decimal = rem(tenths, 10)

    if decimal == 0,
      do: "#{whole}K",
      else: "#{whole}.#{decimal}K"
  end

  def format_count(n) when is_integer(n) and n <= -1_000 do
    "-" <> format_count(abs(n))
  end
end
