defmodule KristasDogsWeb.StatsLive.Components.BeeswarmChart do
  @moduledoc """
  Renders a KristasDogsWeb.StatsLive.ChartGeometry beeswarm layout: axes,
  gridlines, category labels, median ticks, and the shelter-wide
  reference line as inline SVG, with the per-dog dots drawn on a canvas
  layered on top (see KristasDogsWeb.StatsLive.Components.ChartDotsCanvas)
  instead of as SVG circles. With about 3200 dogs per chart, one SVG
  element per dot made the page's DOM enormous and slow to build. See
  docs/superpowers/specs/2026-09-27-stats-canvas-charts-design.md.

  Clicking a dot shows a tooltip with the dog's name, id, its X-axis
  value (the category), and its Y-axis value (days listed). Click
  handling lives entirely in JS (assets/js/stats_live/chart_canvas.js),
  since canvas has no DOM elements for the old pure-CSS `:hover` trick to
  attach to. See
  docs/superpowers/specs/2026-09-24-adoption-time-stats-design.md for
  the original chart design.

  Set `vertical_labels` to true for charts with many long category
  names (like breed) so labels rotate -90 degrees and don't overlap.
  Pair this with a larger `:plot_bottom` option passed to
  `ChartGeometry.beeswarm_layout/3` so the rotated labels have room.

  Set `responsive` to true for charts with few, wide columns (like size
  and gender) so the SVG (and canvas overlay) scale to fit their
  container instead of overflowing at a fixed pixel width. Leave it
  false for charts meant to scroll horizontally at their full size (like
  breed).
  """

  use Phoenix.Component

  import KristasDogsWeb.StatsLive.Components.ChartDotsCanvas

  attr :chart, :map, required: true
  attr :chart_name, :string, required: true
  attr :dots_url, :string, required: true
  attr :x_label, :string, required: true
  attr :vertical_labels, :boolean, default: false
  attr :responsive, :boolean, default: false

  def beeswarm_chart(assigns) do
    ~H"""
    <div class="relative">
      <svg
        width={if @responsive, do: "100%", else: @chart.width}
        height={if @responsive, do: nil, else: @chart.height}
        viewBox={"0 0 #{@chart.width} #{@chart.height}"}
        class="bg-white"
      >
        <g :for={tick <- @chart.y_ticks}>
          <line x1={@chart.plot_left} x2={@chart.width} y1={tick.y} y2={tick.y} stroke="#e2e8f0" stroke-width="1" />
          <text x={@chart.plot_left - 6} y={tick.y + 3} text-anchor="end" font-size="9" fill="#94a3b8">{tick.label}</text>
        </g>
        <text
          transform={"translate(14, #{@chart.axis_center_y}) rotate(-90)"}
          text-anchor="middle"
          font-size="9"
          fill="#94a3b8"
        >Days Listed</text>
        <line
          :if={@chart.reference_y}
          x1="0"
          x2={@chart.width}
          y1={@chart.reference_y}
          y2={@chart.reference_y}
          stroke="#94a3b8"
          stroke-dasharray="4 2"
        />
        <text
          :if={@chart.reference_y}
          x={@chart.width - 4}
          y={@chart.reference_y - 4}
          text-anchor="end"
          font-size="10"
          fill="#64748b"
        >{"median: #{format_days(@chart.reference_days)}"}</text>
        <g :for={column <- @chart.columns}>
          <line
            x1={column.x - 15}
            x2={column.x + 15}
            y1={column.median_y}
            y2={column.median_y}
            stroke="#0f172a"
            stroke-width="2"
          />
          <text
            :if={!@vertical_labels}
            x={column.x}
            y={column.label_y}
            text-anchor="middle"
            font-size="10"
          >{column.category}</text>
          <text
            :if={@vertical_labels}
            transform={"translate(#{column.x}, #{column.label_y}) rotate(-90)"}
            text-anchor="end"
            font-size="10"
          >{column.category}</text>
        </g>
      </svg>
      <.chart_dots_canvas chart={@chart} chart_name={@chart_name} dots_url={@dots_url} x_label={@x_label} responsive={@responsive} />
    </div>
    <p class="mt-1 text-xs text-zinc-400">Click a dot for details</p>
    """
  end

  defp format_days(days) do
    :erlang.float_to_binary(days, decimals: 1)
  end
end
