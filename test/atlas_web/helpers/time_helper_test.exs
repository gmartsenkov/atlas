defmodule AtlasWeb.TimeHelperTest do
  use ExUnit.Case, async: true

  import AtlasWeb.TimeHelper

  describe "time_ago/1" do
    test "returns 'just now' for less than 60 seconds ago" do
      assert time_ago(seconds_ago(0)) == "just now"
      assert time_ago(seconds_ago(30)) == "just now"
      assert time_ago(seconds_ago(59)) == "just now"
    end

    test "returns minutes ago" do
      assert time_ago(seconds_ago(60)) == "1m ago"
      assert time_ago(seconds_ago(300)) == "5m ago"
      assert time_ago(seconds_ago(3599)) == "59m ago"
    end

    test "returns hours ago" do
      assert time_ago(seconds_ago(3600)) == "1h ago"
      assert time_ago(seconds_ago(7200)) == "2h ago"
      assert time_ago(seconds_ago(86_399)) == "23h ago"
    end

    test "returns days ago" do
      assert time_ago(seconds_ago(86_400)) == "1d ago"
      assert time_ago(seconds_ago(604_800)) == "7d ago"
      assert time_ago(seconds_ago(2_591_999)) == "29d ago"
    end

    test "returns months ago" do
      assert time_ago(seconds_ago(2_592_000)) == "1mo ago"
      assert time_ago(seconds_ago(15_552_000)) == "6mo ago"
      assert time_ago(seconds_ago(31_535_999)) == "12mo ago"
    end

    test "returns years ago" do
      assert time_ago(seconds_ago(31_536_000)) == "1y ago"
      assert time_ago(seconds_ago(94_608_000)) == "3y ago"
    end

    test "works with NaiveDateTime" do
      naive = NaiveDateTime.add(NaiveDateTime.utc_now(), -3600, :second)
      assert time_ago(naive) == "1h ago"
    end
  end

  defp seconds_ago(seconds) do
    DateTime.add(DateTime.utc_now(), -seconds, :second)
  end
end
