defmodule KristasDogsWeb.StatsLive.ChartGeometry do
  @moduledoc """
  Pure geometry calculations for the adoption-stats SVG charts — turns
  KristasDogs.DogStats results into pixel coordinates. No Ecto, no HTML,
  fully unit testable without a database or a rendered page.
  """

  @column_width 60
  @jitter_step 6
  @max_jitter_magnitude 25
  @y_band_size 3
  @plot_top 20
  @plot_bottom 20
  @plot_height 400
  @scatter_width 600
  @scatter_padding 20

  @doc """
  Builds the layout for a beeswarm chart from a list of
  `%{category: String.t(), n: pos_integer(), median_days: number(),
  dogs: [%{id: integer(), name: String.t(), days: number()}]}` (as
  returned by `KristasDogs.DogStats.breed_groups/0`, `.size_groups/0`,
  `.gender_groups/0`), plus the shelter-wide overall median
  days-to-adoption (for the reference line, or nil to omit it).

  Columns appear in the same order as the input list — callers are
  expected to have already sorted groups the way they want them
  displayed (DogStats sorts ascending by median_days). Each dot carries
  its dog's `id`/`name` for the hover tooltip.
  """
  def beeswarm_layout([], _reference_days), do: %{width: 0, height: @plot_height, columns: [], dots: [], reference_y: nil}

  def beeswarm_layout(groups, reference_days) do
    all_days = groups |> Enum.flat_map(fn group -> Enum.map(group.dogs, & &1.days) end) |> maybe_include(reference_days)
    {min_days, max_days} = Enum.min_max(all_days)

    columns =
      groups
      |> Enum.with_index()
      |> Enum.map(fn {group, index} ->
        %{
          category: group.category,
          x: column_center_x(index),
          n: group.n,
          median_y: scale_days_to_y(group.median_days, min_days, max_days)
        }
      end)

    dots =
      groups
      |> Enum.with_index()
      |> Enum.flat_map(fn {group, column_index} ->
        column_x = column_center_x(column_index)

        group.dogs
        |> Enum.map(fn dog -> {dog, scale_days_to_y(dog.days, min_days, max_days)} end)
        |> Enum.group_by(fn {_dog, y} -> round(y / @y_band_size) end)
        |> Enum.flat_map(fn {_band, dogs_in_band} ->
          step = band_jitter_step(length(dogs_in_band))

          dogs_in_band
          |> Enum.with_index()
          |> Enum.map(fn {{dog, y}, dot_index} ->
            %{
              x: column_x + jitter_offset(dot_index) * step,
              y: y,
              id: dog.id,
              name: dog.name
            }
          end)
        end)
      end)

    %{
      width: length(groups) * @column_width,
      height: @plot_height,
      columns: columns,
      dots: dots,
      reference_y: reference_y(reference_days, min_days, max_days)
    }
  end

  @doc """
  Builds the layout for a scatterplot from a list of `%{id: integer(),
  name: String.t(), value: number(), days: number()}` (as returned by
  `KristasDogs.DogStats.age_points/0` / `.weight_points/0`), plus the
  shelter-wide overall median days-to-adoption (for the reference line,
  or nil to omit it). Each dot carries its dog's `id`/`name` for the
  hover tooltip.
  """
  def scatter_layout([], _reference_days), do: %{width: @scatter_width, height: @plot_height, dots: [], reference_y: nil}

  def scatter_layout(points, reference_days) do
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
          name: name
        }
      end)

    %{
      width: @scatter_width,
      height: @plot_height,
      dots: dots,
      reference_y: reference_y(reference_days, min_days, max_days)
    }
  end

  defp column_center_x(index), do: index * @column_width + @column_width / 2

  defp reference_y(nil, _min_days, _max_days), do: nil
  defp reference_y(reference_days, min_days, max_days), do: scale_days_to_y(reference_days, min_days, max_days)

  defp maybe_include(list, nil), do: list
  defp maybe_include(list, value), do: [value | list]

  defp scale_days_to_y(_days, min_days, max_days) when min_days == max_days do
    @plot_top + (@plot_height - @plot_top - @plot_bottom) / 2
  end

  defp scale_days_to_y(days, min_days, max_days) do
    usable_height = @plot_height - @plot_top - @plot_bottom
    # Log scale: adoption times are right-skewed with a long tail, so a
    # linear scale squeezes most dots into a sliver. +1 keeps 0 defined.
    log_days = :math.log(days + 1)
    log_min = :math.log(min_days + 1)
    log_max = :math.log(max_days + 1)
    ratio = (log_days - log_min) / (log_max - log_min)
    # Standard axis convention: the value increases upward, so a larger
    # days value gets a smaller SVG y-pixel (nearer the top of the chart).
    @plot_top + (1 - ratio) * usable_height
  end

  defp scale_value_to_x(_value, min_x, max_x) when min_x == max_x do
    @scatter_width / 2
  end

  defp scale_value_to_x(value, min_x, max_x) do
    usable_width = @scatter_width - 2 * @scatter_padding
    ratio = (value - min_x) / (max_x - min_x)
    @scatter_padding + ratio * usable_width
  end

  defp jitter_offset(index) do
    magnitude = div(index + 1, 2)
    sign = if rem(index, 2) == 0, do: 1, else: -1
    magnitude * sign
  end

  defp band_jitter_step(band_size) do
    max_magnitude_units = jitter_offset(band_size - 1) |> abs()

    if max_magnitude_units == 0 do
      0
    else
      min(@jitter_step, @max_jitter_magnitude / max_magnitude_units)
    end
  end
end
