defmodule KristasDogsWeb.StatsLive.Components.BeeswarmChart do
  @moduledoc """
  Renders a KristasDogsWeb.StatsLive.ChartGeometry beeswarm layout as an
  inline SVG. It shows one dot per dog. Each dot is jittered within its
  category's column. It shows a median tick per column, a "median: X"
  label on the shelter-wide reference line, and can also show a
  shelter-wide reference line.

  Each dot shows an instant hover tooltip with the dog's name, id, its
  X-axis value (the category), and its Y-axis value (days to adoption).
  This is a debug and spot-check tool. See
  docs/superpowers/specs/2026-09-24-adoption-time-stats-design.md for
  details.

  The tooltip and a highlight ring both use a pure CSS `:hover` rule. No
  JS is used. The hovered dot's group gets `isolation: isolate` and
  `z-index: 1` on hover so its tooltip paints above every other dot, not
  just the ones drawn earlier in the SVG.

  Set `vertical_labels` to true for charts with many long category
  names (like breed) so labels rotate -90 degrees and don't overlap.
  Pair this with a larger `:plot_bottom` option passed to
  `ChartGeometry.beeswarm_layout/3` so the rotated labels have room.

  Set `responsive` to true for charts with few, wide columns (like size
  and gender) so the SVG scales to fit its container instead of
  overflowing at a fixed pixel width. Leave it false for charts meant to
  scroll horizontally at their full size (like breed).
  """

  use Phoenix.Component

  attr :chart, :map, required: true
  attr :x_label, :string, required: true
  attr :vertical_labels, :boolean, default: false
  attr :responsive, :boolean, default: false

  def beeswarm_chart(assigns) do
    ~H"""
    <svg
      width={if @responsive, do: "100%", else: @chart.width}
      height={if @responsive, do: nil, else: @chart.height}
      viewBox={"0 0 #{@chart.width} #{@chart.height}"}
      class="bg-white"
    >
      <style>
        .dot-group { isolation: isolate; }
        .dot-highlight, .dot-tooltip { opacity: 0; pointer-events: none; }
        .dot-group:hover { z-index: 1; }
        .dot-group:hover .dot-highlight, .dot-group:hover .dot-tooltip { opacity: 1; }
      </style>
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
      <g :for={dot <- @chart.dots} class="dot-group">
        <circle class="dot-highlight" cx={dot.x} cy={dot.y} r="7" fill="none" stroke="#0284c7" stroke-width="2" />
        <circle cx={dot.x} cy={dot.y} r="3" fill="#0284c7" fill-opacity="0.6" />
        <% tooltip =
          tooltip_layout(
            dot,
            ["#{dot.name} (ID: #{dot.id})", "#{@x_label}: #{dot.category}", "Days to Adoption: #{dot.days}"],
            @chart.width
          ) %>
        <g class="dot-tooltip">
          <rect x={tooltip.x} y={tooltip.y} width={tooltip.width} height={tooltip.height} rx="4" fill="#0f172a" fill-opacity="0.94" />
          <text :for={{line, i} <- Enum.with_index(tooltip.lines)} x={tooltip.text_x} y={tooltip.y + tooltip_baseline(i)} fill="white" font-size="11">{line}</text>
        </g>
      </g>
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
    """
  end

  defp tooltip_layout(dot, lines, chart_width) do
    width = (lines |> Enum.map(&String.length/1) |> Enum.max()) * 6 + 16
    height = length(lines) * 15 + 16

    x = max(0, min(dot.x + 8, chart_width - width))
    y = max(0, dot.y - height - 6)

    %{x: x, y: y, width: width, height: height, text_x: x + 8, lines: lines}
  end

  defp tooltip_baseline(index) do
    8 + (index + 1) * 15 - 4
  end

  defp format_days(days) do
    :erlang.float_to_binary(days, decimals: 1)
  end
end
