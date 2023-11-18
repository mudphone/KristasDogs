defmodule KristasDogsWeb.DogsLive.Index do
  use KristasDogsWeb, :live_view

  alias KristasDogs.Houses
  alias KristasDogs.Houses.Pet

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> apply_action(socket.assigns.live_action)
      # |> assign(
      #   shown_dogs: Houses.list_shown_dogs(),
      #   archived_dogs: Houses.list_archived_dogs()
      # )
    {:ok, socket}
  end

  # @impl true
  # def handle_params(_params, _url, socket) do
  #   socket =
  #     socket
  #     |> apply_action(socket.assigns.live_action)
  #   {:noreply, socket}
  # end

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

  defp apply_action(socket, :archive) do
    dogs = Houses.list_archived_dogs()
    socket
    |> assign(:page_title, "Archived")
    |> assign(dogs: dogs)
  end

  defp date_ago(utc) do
    {:ok, ago} = utc |> Timex.format("{relative}", :relative)
    ago
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
