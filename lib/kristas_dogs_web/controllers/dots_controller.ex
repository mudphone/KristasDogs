defmodule KristasDogsWeb.DotsController do
  @moduledoc """
  Serves each stats chart's per-dog dot data (id, pixel x/y, name,
  category/value label, days-to-adoption) as JSON, for the canvas overlay
  that draws and hit-tests dots client-side. See
  docs/superpowers/specs/2026-09-27-stats-canvas-charts-design.md.

  Coordinates are computed once here via KristasDogsWeb.StatsLive.Charts
  (the same functions StatsLive.Index uses for the SVG chrome), not
  recomputed client-side, so there's a single implementation of the
  beeswarm packing / scatter scaling logic.

  Responses are also cached in memory (KristasDogs.DotsCache), keyed on
  a cheap data-version check, so repeat or 304 requests skip the query,
  layout, encode, and hash work when the data has not changed. The
  cache version also includes the deployed image reference, so a new
  deploy invalidates all cached entries even if no pet data changed.
  """

  use KristasDogsWeb, :controller

  alias KristasDogs.DogStats
  alias KristasDogsWeb.StatsLive.Charts
  alias KristasDogsWeb.StatsLive.Components.ScatterChart

  def breed(conn, _params), do: render_dots(conn, :breed, &Charts.breed_chart/0)
  def size(conn, _params), do: render_dots(conn, :size, &Charts.size_chart/0)
  def gender(conn, _params), do: render_dots(conn, :gender, &Charts.gender_chart/0)
  def age(conn, _params), do: render_dots(conn, :age, &Charts.age_chart/0, :age_months)
  def weight(conn, _params), do: render_dots(conn, :weight, &Charts.weight_chart/0, :raw)

  defp render_dots(conn, chart_key, chart_fn, value_format \\ nil) do
    {body, etag} =
      KristasDogs.DotsCache.fetch(chart_key, &cache_version/0, fn ->
        chart = chart_fn.()
        body = chart.dots |> Enum.map(&dot_payload(&1, value_format)) |> Jason.encode!()
        {body, etag_for(body)}
      end)

    conn = put_resp_header(conn, "cache-control", "no-cache")

    if etag in get_req_header(conn, "if-none-match") do
      conn |> put_resp_header("etag", etag) |> send_resp(304, "")
    else
      conn
      |> put_resp_content_type("application/json")
      |> put_resp_header("etag", etag)
      |> send_resp(200, body)
    end
  end

  defp dot_payload(%{category: category} = dot, _value_format) do
    %{id: dot.id, x: dot.x, y: dot.y, name: dot.name, category: category, days: dot.days}
  end

  defp dot_payload(%{value: value} = dot, value_format) do
    category = value |> ScatterChart.format_value(value_format) |> to_string()
    %{id: dot.id, x: dot.x, y: dot.y, name: dot.name, category: category, days: dot.days}
  end

  defp cache_version do
    {DogStats.data_version(), Application.get_env(:kristas_dogs, :image_ref)}
  end

  defp etag_for(body) do
    hash = :crypto.hash(:sha256, body) |> Base.encode16(case: :lower)
    ~s("#{hash}")
  end
end
