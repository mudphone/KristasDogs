defmodule KristasDogsWeb.StatsLive.ChartGeometry do
  @moduledoc """
  Pure geometry calculations for the adoption-stats SVG charts. Turns
  KristasDogs.DogStats results into pixel coordinates. No Ecto, no HTML,
  fully unit testable without a database or a rendered page.
  """

  @min_column_width 60
  @target_chart_width 900
  @jitter_step 6
  @min_jitter_magnitude 25
  @jitter_margin 15
  @y_band_size 3
  @plot_top 20
  @usable_height 360
  @default_plot_bottom 20
  @scatter_width 600
  @scatter_padding 20
  @plot_left 50
  @tick_days [0, 7, 30, 90, 365]

  @doc """
  Builds the layout for a beeswarm chart from a list of
  `%{category: String.t(), n: pos_integer(), median_days: number(),
  dogs: [%{id: integer(), name: String.t(), days: number()}]}` (as
  returned by `KristasDogs.DogStats.breed_groups/0`, `.size_groups/0`,
  `.gender_groups/0`), plus the shelter-wide overall median
  days-to-adoption (for the reference line, or nil to omit it).

  Columns appear in the same order as the input list. Callers should
  sort groups the way they want them displayed first.

  Column width adapts to the number of groups: `max(60, 900 / n)`, so a
  chart with few categories gets wider columns automatically.

  Options:
  - `:plot_bottom` - extra vertical space below the plotted dots, for
    category labels. Defaults to 20. Pass a larger value (e.g. 200) for
    charts with long labels shown rotated.
  """
  def beeswarm_layout(groups, reference_days, opts \\ [])

  def beeswarm_layout([], _reference_days, opts) do
    plot_bottom = Keyword.get(opts, :plot_bottom, @default_plot_bottom)

    %{
      width: 0,
      height: @plot_top + @usable_height + plot_bottom,
      columns: [],
      dots: [],
      reference_y: nil,
      reference_days: nil,
      plot_left: @plot_left,
      axis_center_y: axis_center_y(),
      y_ticks: []
    }
  end

  def beeswarm_layout(groups, reference_days, opts) do
    plot_bottom = Keyword.get(opts, :plot_bottom, @default_plot_bottom)
    height = @plot_top + @usable_height + plot_bottom
    col_width = column_width(length(groups))
    label_y = @plot_top + @usable_height + 14

    all_days = groups |> Enum.flat_map(fn group -> Enum.map(group.dogs, & &1.days) end) |> maybe_include(reference_days)
    {min_days, max_days} = Enum.min_max(all_days)

    columns =
      groups
      |> Enum.with_index()
      |> Enum.map(fn {group, index} ->
        %{
          category: group.category,
          x: column_center_x(index, col_width),
          n: group.n,
          median_y: scale_days_to_y(group.median_days, min_days, max_days),
          label_y: label_y
        }
      end)

    dots =
      groups
      |> Enum.with_index()
      |> Enum.flat_map(fn {group, column_index} ->
        column_x = column_center_x(column_index, col_width)
        jitter_magnitude = column_jitter_magnitude(col_width)

        group.dogs
        |> Enum.map(fn dog -> {dog, scale_days_to_y(dog.days, min_days, max_days)} end)
        |> Enum.group_by(fn {_dog, y} -> round(y / @y_band_size) end)
        |> Enum.flat_map(fn {_band, dogs_in_band} ->
          step = band_jitter_step(length(dogs_in_band), jitter_magnitude)

          dogs_in_band
          |> Enum.with_index()
          |> Enum.map(fn {{dog, y}, dot_index} ->
            %{
              x: column_x + jitter_offset(dot_index) * step,
              y: y,
              id: dog.id,
              name: dog.name,
              category: group.category,
              days: dog.days
            }
          end)
        end)
      end)

    %{
      width: length(groups) * col_width + @plot_left,
      height: height,
      columns: columns,
      dots: dots,
      reference_y: reference_y(reference_days, min_days, max_days),
      reference_days: reference_days,
      plot_left: @plot_left,
      axis_center_y: axis_center_y(),
      y_ticks: y_ticks(min_days, max_days)
    }
  end

  @doc """
  Builds the layout for a scatterplot from a list of `%{id: integer(),
  name: String.t(), value: number(), days: number()}` (as returned by
  `KristasDogs.DogStats.age_points/0` / `.weight_points/0`), plus the
  shelter-wide overall median days-to-adoption (for the reference line,
  or nil to omit it).

  Options:
  - `:x_tick_candidates` - a list of "nice" round values (in the same
    unit as `value`, e.g. months for age or lbs for weight) to consider
    as X-axis ticks. Only the ones that actually fall within the data's
    own value range are shown. Defaults to `[]` (no X-axis ticks).
  - `:x_tick_label` - a function from tick value to display label.
    Defaults to truncating the value to a whole number string.
  """
  def scatter_layout(points, reference_days, opts \\ [])

  def scatter_layout([], _reference_days, _opts) do
    %{
      width: @scatter_width,
      height: @plot_top + @usable_height + @default_plot_bottom,
      dots: [],
      reference_y: nil,
      reference_days: nil,
      plot_left: @plot_left,
      axis_center_y: axis_center_y(),
      y_ticks: [],
      x_axis_y: @plot_top + @usable_height,
      x_ticks: []
    }
  end

  def scatter_layout(points, reference_days, opts) do
    x_tick_candidates = Keyword.get(opts, :x_tick_candidates, [])
    x_tick_label = Keyword.get(opts, :x_tick_label, &default_x_tick_label/1)

    days_values = points |> Enum.map(& &1.days) |> maybe_include(reference_days)
    {min_days, max_days} = Enum.min_max(days_values)

    x_values = Enum.map(points, & &1.value)
    {min_x, max_x} = Enum.min_max(x_values)

    dots =
      Enum.map(points, fn %{id: id, name: name, value: value, days: days} ->
        %{
          x: scale_value_to_x(value, min_x, max_x),
          y: scale_days_to_y(days, min_days, max_days),
          id: id,
          name: name,
          value: value,
          days: days
        }
      end)

    %{
      width: @scatter_width,
      height: @plot_top + @usable_height + @default_plot_bottom,
      dots: dots,
      reference_y: reference_y(reference_days, min_days, max_days),
      reference_days: reference_days,
      plot_left: @plot_left,
      axis_center_y: axis_center_y(),
      y_ticks: y_ticks(min_days, max_days),
      x_axis_y: @plot_top + @usable_height,
      x_ticks: x_ticks(min_x, max_x, x_tick_candidates, x_tick_label)
    }
  end

  defp column_width(num_groups) do
    max(@min_column_width, div(@target_chart_width, max(num_groups, 1)))
  end

  defp column_center_x(index, col_width), do: index * col_width + col_width / 2 + @plot_left

  defp reference_y(nil, _min_days, _max_days), do: nil
  defp reference_y(reference_days, min_days, max_days), do: scale_days_to_y(reference_days, min_days, max_days)

  defp y_ticks(min_days, max_days) do
    @tick_days
    |> Enum.filter(&(&1 >= min_days and &1 <= max_days))
    |> Enum.map(fn days -> %{y: scale_days_to_y(days, min_days, max_days), label: "#{days}d"} end)
  end

  defp x_ticks(min_x, max_x, candidates, label_fn) do
    candidates
    |> Enum.filter(&(&1 >= min_x and &1 <= max_x))
    |> Enum.map(fn value -> %{x: scale_value_to_x(value, min_x, max_x), label: label_fn.(value)} end)
  end

  defp default_x_tick_label(value), do: "#{trunc(value)}"

  defp axis_center_y do
    @plot_top + @usable_height / 2
  end

  defp maybe_include(list, nil), do: list
  defp maybe_include(list, value), do: [value | list]

  defp scale_days_to_y(_days, min_days, max_days) when min_days == max_days do
    @plot_top + @usable_height / 2
  end

  defp scale_days_to_y(days, min_days, max_days) do
    # Log scale: adoption times are right-skewed with a long tail, so a
    # linear scale squeezes most dots into a sliver. +1 keeps 0 defined.
    log_days = :math.log(days + 1)
    log_min = :math.log(min_days + 1)
    log_max = :math.log(max_days + 1)
    ratio = (log_days - log_min) / (log_max - log_min)
    # Standard axis convention: the value increases upward, so a larger
    # days value gets a smaller SVG y-pixel (nearer the top of the chart).
    @plot_top + (1 - ratio) * @usable_height
  end

  defp scale_value_to_x(_value, min_x, max_x) when min_x == max_x do
    @plot_left + (@scatter_width - @plot_left - @scatter_padding) / 2
  end

  defp scale_value_to_x(value, min_x, max_x) do
    usable_width = @scatter_width - @plot_left - @scatter_padding
    ratio = (value - min_x) / (max_x - min_x)
    @plot_left + ratio * usable_width
  end

  defp jitter_offset(index) do
    magnitude = div(index + 1, 2)
    sign = if rem(index, 2) == 0, do: 1, else: -1
    magnitude * sign
  end

  defp band_jitter_step(band_size, jitter_magnitude) do
    max_magnitude_units = jitter_offset(band_size - 1) |> abs()

    if max_magnitude_units == 0 do
      0
    else
      min(@jitter_step, jitter_magnitude / max_magnitude_units)
    end
  end

  defp column_jitter_magnitude(col_width) do
    max(@min_jitter_magnitude, col_width / 2 - @jitter_margin)
  end
end
