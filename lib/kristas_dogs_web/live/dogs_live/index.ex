defmodule KristasDogsWeb.DogsLive.Index do
  use KristasDogsWeb, :live_view

  alias KristasDogs.Houses
  alias KristasDogs.Stats
  alias KristasDogs.Stats.PetCount
  alias KristasDogsWeb.DogsLive.DogList
  alias KristasDogsWeb.DogsLive.NavMenu

  @impl true
  def mount(_params, _session, socket) do
    event_data = %{latest_counts: get_latest_counts()}
    socket =
      socket
      |> assign(
        page_name: :current,
        search_value: ""
      )
      |> apply_action(socket.assigns.live_action)
      |> push_event("DogsLive.Index.init", event_data)
    {:ok, socket}
  end

  # @impl true
  # def handle_params(_params, _url, socket) do
  #   IO.inspect("handle_params no page")
  #   socket =
  #     socket
  #     |> apply_action(socket.assigns.live_action)
  #   {:noreply, socket}
  # end

  @impl true
  def handle_event("search", %{"dog_name" => dog_name}, socket) do
    dogs = Houses.search_shown_dogs(dog_name)
    socket =
      socket
      |> assign(
        dogs: dogs,
        search_value: dog_name,
        dogs_shown: Enum.count(dogs)
      )
    {:noreply, socket}
  end

  @impl true
  def handle_event("clear", _params, socket) do
    socket =
      socket
      |> assign(search_value: "")
      |> apply_action(socket.assigns.live_action)
    {:noreply, socket}
  end

  defp apply_action(socket, :index) do
    count = Houses.count_shown_dogs()
    socket
    |> assign(:page_title, "Current")
    |> assign(
      dogs: Houses.list_shown_dogs(),
      num_dogs: count,
      dogs_shown: count
    )
  end

  defp get_latest_counts() do
    Stats.list_latest_pet_counts()
    |> Enum.map(fn %PetCount{} = pet_count ->
      %{count: pet_count.count, count_at: pet_count.count_at}
    end)
  end
end
