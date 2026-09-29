defmodule KristasDogsWeb.StatsLive.ChartsTest do
  use KristasDogs.DataCase

  alias KristasDogsWeb.StatsLive.Charts

  import KristasDogs.DogStatsFixtures

  describe "breed_chart/1" do
    test "builds a beeswarm layout from breed_groups with extra bottom room for rotated labels" do
      listed_dog_fixture()

      chart = Charts.breed_chart(nil)

      assert [%{category: "Terrier"}] = chart.dots
      # Default plot_bottom is 20 (height 400); breed adds 200 more for
      # the rotated category labels.
      assert chart.height == 400 + 180
    end
  end

  describe "size_chart/1" do
    test "builds a beeswarm layout from size_groups" do
      listed_dog_fixture()

      chart = Charts.size_chart(nil)

      assert [%{category: "Medium"}] = chart.dots
      assert chart.height == 400
    end
  end

  describe "gender_chart/1" do
    test "builds a beeswarm layout from gender_groups" do
      listed_dog_fixture()

      chart = Charts.gender_chart(nil)

      assert [%{category: "Male"}] = chart.dots
    end
  end

  describe "age_chart/1" do
    test "builds a scatter layout from age_points with month/year tick labels" do
      listed_dog_fixture(%{normal_age_months: 3})
      listed_dog_fixture(%{normal_age_months: 120})

      chart = Charts.age_chart(nil)

      assert length(chart.dots) == 2
      assert Enum.map(chart.x_ticks, & &1.label) == ["6m", "12m", "2y", "5y", "10y"]
    end
  end

  describe "weight_chart/1" do
    test "builds a scatter layout from weight_points" do
      listed_dog_fixture(%{normal_weight_lbs: 5.0})
      listed_dog_fixture(%{normal_weight_lbs: 90.0})

      chart = Charts.weight_chart(nil)

      assert length(chart.dots) == 2
      assert Enum.map(chart.x_ticks, & &1.label) == ["10", "25", "50", "75"]
    end
  end

  test "reference_days defaults to the overall median when not given explicitly" do
    listed_dog_fixture(%{
      inserted_at: ~U[2025-07-01 00:00:00Z],
      removed_from_website_at: ~U[2025-07-11 00:00:00Z]
    })

    assert Charts.breed_chart().reference_days == 10.0
  end
end
