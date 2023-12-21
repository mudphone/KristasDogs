defmodule KristasDogsWeb.DogsLive.DogList do
  use Phoenix.LiveComponent
  use Phoenix.VerifiedRoutes,
    endpoint: KristasDogsWeb.Endpoint,
    router: KristasDogsWeb.Router

  alias KristasDogs.Houses
  alias KristasDogs.Houses.Pet

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  defp date_ago(utc) do
    {:ok, ago} =
      utc
      |> Timex.format("{relative}", :relative)
    ago
    |> String.replace("hour", "hr")
    |> String.replace("minute", "min")
    |> String.replace("second", "sec")
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

  defp size_emoji(%Pet{size: size}) do
    case String.downcase(size) do
      "small" -> "🤏"
      "large" -> "🙌"
      _ -> ""
    end
  end
end
