defmodule KristasDogsWeb.StatsLive.Index do
  use KristasDogsWeb, :live_view

  alias KristasDogs.DogStats
  alias KristasDogsWeb.StatsLive.Charts
  alias KristasDogsWeb.DogsLive.NavMenu

  import KristasDogsWeb.StatsLive.Components.BeeswarmChart
  import KristasDogsWeb.StatsLive.Components.ScatterChart

  @impl true
  def mount(_params, _session, socket) do
    reference_days = DogStats.overall_median_days()

    socket =
      socket
      |> assign(page_name: :stats, page_title: "Stats")
      |> assign(breed_chart: Charts.breed_chart(reference_days) |> Map.delete(:dots))
      |> assign(size_chart: Charts.size_chart(reference_days) |> Map.delete(:dots))
      |> assign(gender_chart: Charts.gender_chart(reference_days) |> Map.delete(:dots))
      |> assign(age_chart: Charts.age_chart(reference_days) |> Map.delete(:dots))
      |> assign(weight_chart: Charts.weight_chart(reference_days) |> Map.delete(:dots))

    {:ok, socket}
  end
end
