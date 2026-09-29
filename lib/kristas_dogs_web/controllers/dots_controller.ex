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
  """

  use KristasDogsWeb, :controller

  alias KristasDogsWeb.StatsLive.Charts
  alias KristasDogsWeb.StatsLive.Components.ScatterChart

  def breed(conn, _params), do: render_dots(conn, Charts.breed_chart())
  def size(conn, _params), do: render_dots(conn, Charts.size_chart())
  def gender(conn, _params), do: render_dots(conn, Charts.gender_chart())
  def age(conn, _params), do: render_dots(conn, Charts.age_chart(), :age_months)
  def weight(conn, _params), do: render_dots(conn, Charts.weight_chart(), :raw)

  defp render_dots(conn, chart, value_format \\ nil) do
    body = chart.dots |> Enum.map(&dot_payload(&1, value_format)) |> Jason.encode!()
    etag = etag_for(body)

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

  defp etag_for(body) do
    hash = :crypto.hash(:sha256, body) |> Base.encode16(case: :lower)
    ~s("#{hash}")
  end
end
