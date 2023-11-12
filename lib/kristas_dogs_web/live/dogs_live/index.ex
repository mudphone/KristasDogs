defmodule KristasDogsWeb.DogsLive.Index do
  use KristasDogsWeb, :live_view

  alias KristasDogs.Houses

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
    #   |> apply_action(socket.assigns.live_action)
    #   |> apply_initial_values(params)
    #   |> assign_form()
      |> assign(
        dogs: Houses.list_dogs()
    #     time_zone_opts: @time_zone_opts,
    #     custom_duration_opts: @custom_duration_options
      )
    {:ok, socket}
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
