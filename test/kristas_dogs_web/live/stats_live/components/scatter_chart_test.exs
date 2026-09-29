defmodule KristasDogsWeb.StatsLive.Components.ScatterChartTest do
  use ExUnit.Case, async: true

  alias KristasDogsWeb.StatsLive.Components.ScatterChart

  describe "format_value/2" do
    test "formats months under 12 as whole months" do
      assert ScatterChart.format_value(6, :age_months) == "6 months"
    end

    test "formats months at or above 12 as decimal years" do
      assert ScatterChart.format_value(24, :age_months) == "2.0 years"
    end

    test "formats a partial year with one decimal place" do
      assert ScatterChart.format_value(18, :age_months) == "1.5 years"
    end

    test "passes non-age values through unchanged" do
      assert ScatterChart.format_value(40.0, :raw) == 40.0
    end
  end
end
