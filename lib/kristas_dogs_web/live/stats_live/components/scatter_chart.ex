defmodule KristasDogsWeb.StatsLive.Components.ScatterChart do
  @moduledoc """
  Renders a KristasDogsWeb.StatsLive.ChartGeometry scatter layout as an
  inline SVG. It shows one dot per dog. It can also show a shelter-wide
  reference line.

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

  def scatter_chart(assigns) do
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
    </svg>
    """
  end
end
