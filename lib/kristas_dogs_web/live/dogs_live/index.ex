defmodule KristasDogsWeb.DogsLive.Index do
  use KristasDogsWeb, :live_view

  alias KristasDogs.Houses
  alias KristasDogs.Houses.Pet

  alias KristasDogsWeb.DogsLive.Pager

  @impl true
  def mount(%{"page" => page}, _session, socket) do
    page = get_page(page)
    IO.inspect("mount only page #{page}")
    socket =
      socket
      |> assign(page: page)
      |> apply_action(socket.assigns.live_action)
    {:ok, socket}
  end

  @impl true
  def mount(_params, _session, socket) do
    IO.inspect("mount with no page")
    socket =
      socket
      |> assign(page: nil)
      |> apply_action(socket.assigns.live_action)
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"page" => page}, _url, socket) do
    page = get_page(page)
    IO.inspect("handle_params page #{page}")
    socket =
      socket
      |> assign(page: page)
      |> apply_action(socket.assigns.live_action)
    {:noreply, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    IO.inspect("handle_params no page")
    socket =
      socket
      |> assign(page: 1)
      |> apply_action(socket.assigns.live_action)
    {:noreply, socket}
  end

  @impl true
  def handle_event("search", %{"dog_name" => dog_name}, socket) do
    archived? = socket.assigns.live_action == :archive
    dogs = Houses.search_dogs(dog_name, archived?)
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

  defp apply_action(%{assigns: %{page: page}} = socket, :archive) do
    IO.inspect("apply_action Page!")
    IO.inspect(page)
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

  defp date_ago(utc) do
    {:ok, ago} =
      utc
      |> Timex.format("{relative}", :relative)
    ago =
      ago
      |> String.replace("hour", "hr")
      |> String.replace("minute", "min")
      |> String.replace("second", "sec")
    "added #{ago}"
  end

  defp date_fmt(utc) do
    utc
    |> DateTime.shift_zone!("Pacific/Honolulu")
    |> Calendar.strftime("%-I:%M%P %a %b %-d, %y %Z")
  end

  @pct_new_range_min 60 * 96 # four days in minutes
  defp pct_new(%Pet{} = pet) do
    mins = Houses.minutes_since_added(pet)
    mins = min(@pct_new_range_min, mins)
    ((@pct_new_range_min - mins) * 100)
    |> div(@pct_new_range_min)
  end
end
