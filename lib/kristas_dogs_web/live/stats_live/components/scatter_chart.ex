defmodule KristasDogsWeb.StatsLive.Components.ScatterChart do
  @moduledoc """
  Renders a KristasDogsWeb.StatsLive.ChartGeometry scatter layout: axes,
  gridlines, and the shelter-wide reference line as inline SVG, with the
  per-dog dots drawn on a <canvas> layered on top (see
  KristasDogsWeb.StatsLive.Components.ChartDotsCanvas) instead of as SVG
  circles -- with ~3200 dogs per chart, one SVG element per dot made the
  page's DOM enormous and slow to build. See
  docs/superpowers/specs/2026-09-27-stats-canvas-charts-design.md.

  Clicking a dot shows a tooltip with the dog's name, id, its X-axis
  value, and its Y-axis value (days to adoption); click handling lives
  entirely in JS (assets/js/stats_live/chart_canvas.js), since canvas has
  no DOM elements for the old pure-CSS `:hover` trick to attach to. See
  docs/superpowers/specs/2026-09-24-adoption-time-stats-design.md for the
  original chart design.

  Set `responsive` to true so the SVG (and canvas overlay) scale to fit
  their container width instead of staying pinned at a fixed pixel
  width.
  """

  use Phoenix.Component

  import KristasDogsWeb.StatsLive.Components.ChartDotsCanvas

  attr :chart, :map, required: true
  attr :chart_name, :string, required: true
  attr :dots_url, :string, required: true
  attr :x_label, :string, required: true
  attr :responsive, :boolean, default: false

  def scatter_chart(assigns) do
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
        >Days to Adoption</text>
        <g :for={tick <- @chart.x_ticks}>
          <line x1={tick.x} x2={tick.x} y1={@chart.x_axis_y} y2={@chart.x_axis_y + 6} stroke="#94a3b8" stroke-width="1" />
          <text x={tick.x} y={@chart.x_axis_y + 16} text-anchor="middle" font-size="9" fill="#94a3b8">{tick.label}</text>
        </g>
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
      </svg>
      <.chart_dots_canvas chart={@chart} chart_name={@chart_name} dots_url={@dots_url} x_label={@x_label} responsive={@responsive} />
    </div>
    <p class="mt-1 text-xs text-zinc-400">Click a dot for details</p>
    """
  end

  @doc """
  Formats a scatter dot's raw X-axis value for display. Age values (in
  months) become "N months"/"N.N years" text; every other format passes
  the raw value through unchanged. Public because
  KristasDogsWeb.DotsController reuses it to format the same value for
  the JSON tooltip payload.
  """
  def format_value(months, :age_months) do
    years = months / 12

    if months >= 12 do
      "#{:erlang.float_to_binary(years, decimals: 1)} years"
    else
      "#{months} months"
    end
  end

  def format_value(value, _format), do: value

  defp format_days(days) do
    :erlang.float_to_binary(days, decimals: 1)
  end
end
