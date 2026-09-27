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
      |> assign(age_chart: ChartGeometry.scatter_layout(DogStats.age_points(), reference_days))
      |> assign(weight_chart: ChartGeometry.scatter_layout(DogStats.weight_points(), reference_days))

    {:ok, socket}
  end
end
