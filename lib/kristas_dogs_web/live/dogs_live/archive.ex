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
  def handle_event("search", %{"dog_name" => dog_name}, %{assigns: %{page: page}} = socket) do
    dogs = Houses.search_archived_dogs(dog_name, %{page: page})
    socket =
      socket
      |> assign(dogs: dogs)
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
    count = Houses.count_archived_dogs()
    socket
    |> assign(
      page_title: "Archived",
      dogs: Houses.list_archived_dogs(page),
      dog_count: count,
      page: page,
      num_pages: num_pages(count)
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
