defmodule KristasDogsWeb.StatsLive.Index do
  use KristasDogsWeb, :live_view

  alias KristasDogs.DogStats
  alias KristasDogsWeb.StatsLive.ChartGeometry
  alias KristasDogsWeb.DogsLive.NavMenu

  import KristasDogsWeb.StatsLive.Components.BeeswarmChart
  import KristasDogsWeb.StatsLive.Components.ScatterChart

  @impl true
  def mount(_params, _session, socket) do
    reference_days = DogStats.overall_median_days()

    socket =
      socket
      |> assign(page_name: :stats, page_title: "Stats")
      |> assign(breed_chart: ChartGeometry.beeswarm_layout(DogStats.breed_groups(), reference_days, plot_bottom: 200))
      |> assign(size_chart: ChartGeometry.beeswarm_layout(DogStats.size_groups(), reference_days))
      |> assign(gender_chart: ChartGeometry.beeswarm_layout(DogStats.gender_groups(), reference_days))
      |> assign(
        age_chart:
          ChartGeometry.scatter_layout(DogStats.age_points(), reference_days,
            x_tick_candidates: [0, 6, 12, 24, 60, 120],
            x_tick_label: &age_tick_label/1
          )
      )
      |> assign(weight_chart: ChartGeometry.scatter_layout(DogStats.weight_points(), reference_days, x_tick_candidates: [0, 10, 25, 50, 75, 100]))

    {:ok, socket}
  end

  # Ticks up to and including 12 months show in months; above that,
  # in years. Both candidate lists are whole-year multiples above 12.
  defp age_tick_label(months) when months <= 12, do: "#{trunc(months)}m"
  defp age_tick_label(months), do: "#{round(months / 12)}y"
end
