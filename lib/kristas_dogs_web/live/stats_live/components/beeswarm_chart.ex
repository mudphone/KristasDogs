defmodule KristasDogsWeb.StatsLive.Components.BeeswarmChart do
  @moduledoc """
  Renders a KristasDogsWeb.StatsLive.ChartGeometry beeswarm layout as an
  inline SVG. It shows one dot per dog. Each dot is jittered within its
  category's column. It shows a median tick per column. It can also show
  a shelter-wide reference line.

  Each dot has a native SVG `<title>` tag. This gives a browser hover
  tooltip with the dog's name and id. This is a debug and spot-check
  tool. See docs/superpowers/specs/2026-09-24-adoption-time-stats-design.md
  for details.

  Each dot also has a highlight ring. The ring appears around the dot
  when the user hovers over it. This uses a pure CSS `:hover` rule. It
  does not use JS.
  """

  use Phoenix.Component

  attr :chart, :map, required: true

  def beeswarm_chart(assigns) do
    ~H"""
    <svg width={@chart.width} height={@chart.height} viewBox={"0 0 #{@chart.width} #{@chart.height}"} class="bg-white">
      <style>
        .dot-highlight { opacity: 0; }
        g.dot-group:hover .dot-highlight { opacity: 1; }
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
        <circle cx={dot.x} cy={dot.y} r="3" fill="#0284c7" fill-opacity="0.6">
          <title>{"#{dot.name} (ID: #{dot.id})"}</title>
        </circle>
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
        <text x={column.x} y={@chart.height - 4} text-anchor="middle" font-size="10">{column.category}</text>
      </g>
    </svg>
    """
  end
end
