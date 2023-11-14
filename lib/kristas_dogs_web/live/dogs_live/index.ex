defmodule KristasDogsWeb.DogsLive.Index do
  use KristasDogsWeb, :live_view

  alias KristasDogs.Houses

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
end
