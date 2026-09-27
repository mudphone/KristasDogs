defmodule KristasDogsWeb.StatsLive.Components.ScatterChart do
  @moduledoc """
  Renders a KristasDogsWeb.StatsLive.ChartGeometry scatter layout as an
  inline SVG. It shows one dot per dog. It can also show a shelter-wide
  reference line.

  Each dot shows an instant hover tooltip with the dog's name, id, its
  X-axis value, and its Y-axis value (days to adoption). This is a debug
  and spot-check tool. See
  docs/superpowers/specs/2026-09-24-adoption-time-stats-design.md for
  details.

  The tooltip and a highlight ring both use a pure CSS `:hover` rule. No
  JS is used. The hovered dot's group gets `isolation: isolate` and
  `z-index: 1` on hover so its tooltip paints above every other dot, not
  just the ones drawn earlier in the SVG.
  """

  use Phoenix.Component

  @tooltip_padding 8
  @tooltip_line_height 15
  @tooltip_char_width 6
  @tooltip_gap 6

  attr :chart, :map, required: true
  attr :x_label, :string, required: true

  def scatter_chart(assigns) do
    ~H"""
    <svg width={@chart.width} height={@chart.height} viewBox={"0 0 #{@chart.width} #{@chart.height}"} class="bg-white">
      <style>
        .dot-group { isolation: isolate; }
        .dot-highlight, .dot-tooltip { opacity: 0; pointer-events: none; }
        .dot-group:hover { z-index: 1; }
        .dot-group:hover .dot-highlight, .dot-group:hover .dot-tooltip { opacity: 1; }
      </style>
      <line
        :if={@chart.reference_y}
        x1="0"
        x2={@chart.width}
        y1={@chart.reference_y}
        y2={@chart.reference_y}
        stroke="#94a3b8"
        stroke-dasharray="4 2"
      />
      <g :for={dot <- @chart.dots} class="dot-group">
        <circle class="dot-highlight" cx={dot.x} cy={dot.y} r="7" fill="none" stroke="#0284c7" stroke-width="2" />
        <circle cx={dot.x} cy={dot.y} r="3" fill="#0284c7" fill-opacity="0.6" />
        <% tooltip =
          tooltip_layout(
            dot,
            ["#{dot.name} (ID: #{dot.id})", "#{@x_label}: #{dot.value}", "Days to Adoption: #{dot.days}"],
            @chart.width
          ) %>
        <g class="dot-tooltip">
          <rect x={tooltip.x} y={tooltip.y} width={tooltip.width} height={tooltip.height} rx="4" fill="#0f172a" fill-opacity="0.94" />
          <text :for={{line, i} <- Enum.with_index(tooltip.lines)} x={tooltip.text_x} y={tooltip.y + tooltip_baseline(i)} fill="white" font-size="11">{line}</text>
        </g>
      </g>
    </svg>
    """
  end

  defp tooltip_layout(dot, lines, chart_width) do
    width = (lines |> Enum.map(&String.length/1) |> Enum.max()) * @tooltip_char_width + @tooltip_padding * 2
    height = length(lines) * @tooltip_line_height + @tooltip_padding * 2

    x = max(0, min(dot.x + 8, chart_width - width))
    y = max(0, dot.y - height - @tooltip_gap)

    %{x: x, y: y, width: width, height: height, text_x: x + @tooltip_padding, lines: lines}
  end

  defp tooltip_baseline(index) do
    @tooltip_padding + (index + 1) * @tooltip_line_height - 4
  end
end
