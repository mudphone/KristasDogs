defmodule KristasDogsWeb.DogsLive.Index do
  use KristasDogsWeb, :live_view

  alias KristasDogs.Houses
  alias KristasDogsWeb.DogsLive.DogList
  alias KristasDogsWeb.DogsLive.NavMenu

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(page_name: :current)
      |> apply_action(socket.assigns.live_action)
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
      |> assign(dogs: dogs)
    {:noreply, socket}
  end

  defp apply_action(socket, :index) do
    dogs = Houses.list_shown_dogs()
    socket
    |> assign(:page_title, "Current")
    |> assign(dogs: dogs)
  end
end
