defmodule KristasDogsWeb.StatsLive.Components.ChartDotsCanvas do
  @moduledoc """
  The canvas overlay that draws a chart's per-dog dots and handles
  click-to-reveal tooltips. Shared by BeeswarmChart and ScatterChart,
  both of which layer this on top of their own SVG chrome at the same
  width and height.

  Drawing and click handling live entirely in the phx-hook `ChartDots`
  (assets/js/stats_live/chart_canvas.js). This component only emits the
  canvas element with the data the hook needs to fetch and position dots.

  Must be placed inside a `position: relative` wrapper alongside the
  chart's `<svg>`, since it's positioned absolutely at (0, 0) to sit
  exactly on top of it.
  """

  use Phoenix.Component

  attr :chart, :map, required: true
  attr :chart_name, :string, required: true
  attr :dots_url, :string, required: true
  attr :x_label, :string, required: true
  attr :responsive, :boolean, default: false

  def chart_dots_canvas(assigns) do
    ~H"""
    <canvas
      id={"chart-dots-#{@chart_name}"}
      phx-hook="ChartDots"
      phx-update="ignore"
      class="absolute left-0 top-0 cursor-pointer"
      style={if @responsive, do: "width: 100%; height: auto;"}
      width={@chart.width}
      height={@chart.height}
      data-dots-url={@dots_url}
      data-x-label={@x_label}
      data-chart-width={@chart.width}
      data-chart-height={@chart.height}
    ></canvas>
    """
  end
end
