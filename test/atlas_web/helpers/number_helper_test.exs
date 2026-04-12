defmodule AtlasWeb.NumberHelperTest do
  use ExUnit.Case, async: true

  import AtlasWeb.NumberHelper

  describe "format_count/1" do
    test "returns small numbers as-is" do
      assert format_count(0) == "0"
      assert format_count(1) == "1"
      assert format_count(42) == "42"
      assert format_count(999) == "999"
    end

    test "formats thousands with K suffix" do
      assert format_count(1_000) == "1K"
      assert format_count(1_500) == "1.5K"
      assert format_count(2_300) == "2.3K"
      assert format_count(10_000) == "10K"
      assert format_count(20_500) == "20.5K"
      assert format_count(300_500) == "300.5K"
    end

    test "truncates rather than rounds" do
      assert format_count(1_999) == "1.9K"
      assert format_count(1_050) == "1K"
      assert format_count(1_099) == "1K"
    end

    test "handles negative numbers" do
      assert format_count(-5) == "-5"
      assert format_count(-999) == "-999"
      assert format_count(-1_500) == "-1.5K"
      assert format_count(-20_000) == "-20K"
    end
  end
end
