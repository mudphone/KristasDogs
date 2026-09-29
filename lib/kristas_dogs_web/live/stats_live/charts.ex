defmodule KristasDogsWeb.StatsLive.Charts do
  @moduledoc """
  Assembles each of the 5 adoption-stats charts' full geometry (dots,
  columns, ticks, reference line) by combining KristasDogs.DogStats query
  results with KristasDogsWeb.StatsLive.ChartGeometry layout options.
  Shared by StatsLive.Index (renders the SVG chrome) and DotsController
  (serves the per-dog dot data as JSON), so both use identical geometry
  instead of duplicating these DogStats + ChartGeometry calls.
  """

  alias KristasDogs.DogStats
  alias KristasDogsWeb.StatsLive.ChartGeometry

  def breed_chart(reference_days \\ DogStats.overall_median_days()) do
    ChartGeometry.beeswarm_layout(DogStats.breed_groups(), reference_days, plot_bottom: 200)
  end

  def size_chart(reference_days \\ DogStats.overall_median_days()) do
    ChartGeometry.beeswarm_layout(DogStats.size_groups(), reference_days)
  end

  def gender_chart(reference_days \\ DogStats.overall_median_days()) do
    ChartGeometry.beeswarm_layout(DogStats.gender_groups(), reference_days)
  end

  def age_chart(reference_days \\ DogStats.overall_median_days()) do
    ChartGeometry.scatter_layout(DogStats.age_points(), reference_days,
      x_tick_candidates: [0, 6, 12, 24, 60, 120],
      x_tick_label: &age_tick_label/1
    )
  end

  def weight_chart(reference_days \\ DogStats.overall_median_days()) do
    ChartGeometry.scatter_layout(DogStats.weight_points(), reference_days, x_tick_candidates: [0, 10, 25, 50, 75, 100])
  end

  # Ticks up to and including 12 months show in months; above that, in
  # years. Both candidate lists are whole-year multiples above 12.
  defp age_tick_label(months) when months <= 12, do: "#{trunc(months)}m"
  defp age_tick_label(months), do: "#{round(months / 12)}y"
end
