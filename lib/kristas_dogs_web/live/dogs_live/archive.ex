defmodule KristasDogsWeb.DogsLive.Archive do
  use KristasDogsWeb, :live_view

  alias KristasDogs.Houses
  alias KristasDogsWeb.DogsLive.DogList
  alias KristasDogsWeb.DogsLive.NavMenu
  alias KristasDogsWeb.DogsLive.Pager

  @default_page 1

  @impl true
  def mount(%{"page" => page}, _session, socket) do
    socket =
      socket
      |> apply_page(page)
    {:ok, socket}
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> apply_page(@default_page)
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"page" => page}, _url, socket) do
    socket =
      socket
      |> apply_page(page)
    {:noreply, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    socket =
      socket
      |> apply_page(@default_page)
    {:noreply, socket}
  end

  @impl true
  def handle_event("search", %{"dog_name" => dog_name}, socket) do
    socket =
      socket
      |> assign(search_value: dog_name)
      |> apply_page(1)
    {:noreply, socket}
  end

  @impl true
  def handle_event("clear", _params, socket) do
    socket =
      socket
      |> assign(search_value: "")
      |> apply_page(1)
    {:noreply, socket}
  end

  defp apply_page(socket, page) do
    page = get_page(page)
    socket
    |> assign(
      page: page,
      page_name: :archive
    )
    |> apply_action(socket.assigns.live_action)
  end

  defp apply_action(%{assigns: %{page: page}} = socket, :index) do
    search_value = Map.get(socket.assigns, :search_value)
    {dogs, count} =
      cond do
        is_nil(search_value) or search_value == "" ->
          dogs = Houses.list_archived_dogs(page)
          count = Houses.count_archived_dogs()
          {dogs, count}
        true ->
          dogs = Houses.search_archived_dogs(search_value, %{page: page})
          count = Houses.count_searched_archived_dogs(search_value)
          {dogs, count}
      end

    socket
    |> assign(
      page_title: "Archived",
      dogs: dogs,
      dog_count: count,
      page: page,
      num_pages: num_pages(count),
      search_value: Map.get(socket.assigns, :search_value)
    )
  end

  defp get_page(nil), do: 1
  defp get_page(p) when is_binary(p) do
    case Integer.parse(p) do
      {i, _} -> i
      :error -> 1
    end
  end
  defp get_page(p), do: p

  defp num_pages(count) do
    (count / Houses.archive_page_size)
    |> Float.ceil()
    |> trunc()
  end
end
