defmodule KristasDogsWeb.StatsLive.ChartGeometryTest do
  use ExUnit.Case, async: true

  alias KristasDogsWeb.StatsLive.ChartGeometry

  describe "beeswarm_layout/2" do
    test "returns an empty layout for no groups" do
      assert ChartGeometry.beeswarm_layout([], nil) == %{
               width: 0,
               height: 400,
               columns: [],
               dots: [],
               reference_y: nil,
               reference_days: nil,
               plot_left: 50,
               axis_center_y: 200.0,
               y_ticks: []
             }
    end

    test "uses wider columns when there are few groups, floors at 60px for many" do
      few_groups = [
        %{category: "Male", n: 1, median_days: 5.0, dogs: [%{id: 1, name: "A", days: 5}]},
        %{category: "Female", n: 1, median_days: 5.0, dogs: [%{id: 2, name: "B", days: 5}]}
      ]

      many_groups = for i <- 1..50, do: %{category: "Breed#{i}", n: 1, median_days: 5.0, dogs: [%{id: i, name: "Dog#{i}", days: 5}]}

      few_layout = ChartGeometry.beeswarm_layout(few_groups, nil)
      many_layout = ChartGeometry.beeswarm_layout(many_groups, nil)

      # width now also includes the fixed 50px left margin reserved for the
      # Y-axis, so subtract it before recovering the per-group column width.
      assert div(few_layout.width - 50, 2) > 400
      assert div(many_layout.width - 50, 50) == 60
    end

    test "plot_bottom option increases total chart height without changing dot positions" do
      groups = [%{category: "Beagle", n: 1, median_days: 5.0, dogs: [%{id: 1, name: "Fido", days: 5}]}]

      default_layout = ChartGeometry.beeswarm_layout(groups, nil)
      tall_layout = ChartGeometry.beeswarm_layout(groups, nil, plot_bottom: 200)

      assert tall_layout.height == default_layout.height + 180
      assert hd(tall_layout.dots).y == hd(default_layout.dots).y
    end

    test "places one column per group, in the given order, each dot within its column" do
      groups = [
        %{category: "Beagle", n: 1, median_days: 5.0, dogs: [%{id: 1, name: "Fido", days: 5}]},
        %{
          category: "Terrier",
          n: 2,
          median_days: 15.0,
          dogs: [%{id: 2, name: "Rex", days: 10}, %{id: 3, name: "Wednesday", days: 20}]
        }
      ]

      layout = ChartGeometry.beeswarm_layout(groups, 10.0)

      # Column width is adaptive: 2 groups get max(60, 900/2) = 450px columns,
      # plus the 50px left margin reserved for the Y-axis.
      assert layout.width == 2 * 450 + 50
      assert [%{category: "Beagle", x: beagle_x}, %{category: "Terrier", x: terrier_x}] = layout.columns
      assert beagle_x < terrier_x
      assert length(layout.dots) == 3
      assert is_float(layout.reference_y)
    end

    test "each dot carries its dog's id and name for the hover tooltip" do
      groups = [%{category: "Beagle", n: 1, median_days: 5.0, dogs: [%{id: 42, name: "Fido", days: 5}]}]

      layout = ChartGeometry.beeswarm_layout(groups, nil)

      assert [%{id: 42, name: "Fido"}] = layout.dots
    end

    test "each dot carries its category and days for the tooltip" do
      groups = [%{category: "Beagle", n: 1, median_days: 5.0, dogs: [%{id: 42, name: "Fido", days: 7}]}]

      layout = ChartGeometry.beeswarm_layout(groups, nil)

      assert [%{category: "Beagle", days: 7}] = layout.dots
    end

    test "a larger days value is plotted nearer the top (smaller y) than a smaller one, standard axis convention" do
      groups = [
        %{
          category: "Mixed",
          n: 2,
          median_days: 15.0,
          dogs: [%{id: 1, name: "Fido", days: 5}, %{id: 2, name: "Rex", days: 25}]
        }
      ]

      layout = ChartGeometry.beeswarm_layout(groups, nil)

      dot_for_5_days = Enum.find(layout.dots, &(&1.id == 1))
      dot_for_25_days = Enum.find(layout.dots, &(&1.id == 2))
      assert dot_for_25_days.y < dot_for_5_days.y
    end

    test "compresses large days values relative to small ones, proving a log (not linear) scale" do
      groups = [
        %{
          category: "Wide range",
          n: 4,
          median_days: 50.0,
          dogs: [
            %{id: 1, name: "A", days: 1},
            %{id: 2, name: "B", days: 11},
            %{id: 3, name: "C", days: 500},
            %{id: 4, name: "D", days: 510}
          ]
        }
      ]

      layout = ChartGeometry.beeswarm_layout(groups, nil)

      dot_a = Enum.find(layout.dots, &(&1.id == 1))
      dot_b = Enum.find(layout.dots, &(&1.id == 2))
      dot_c = Enum.find(layout.dots, &(&1.id == 3))
      dot_d = Enum.find(layout.dots, &(&1.id == 4))

      gap_low = abs(dot_a.y - dot_b.y)
      gap_high = abs(dot_c.y - dot_d.y)

      # Both gaps span exactly 10 raw days, but on a log scale the gap
      # between 1 and 11 days is much larger in pixels than the gap
      # between 500 and 510 days -- a linear scale would make these two
      # gaps identical.
      assert gap_low > gap_high * 5
    end

    test "keeps every dot within its column's bounds even with hundreds of dogs sharing similar days values" do
      dogs = for i <- 1..500, do: %{id: i, name: "Dog#{i}", days: rem(i, 30)}
      other_groups = for i <- 1..89, do: %{category: "Other#{i}", n: 1, median_days: 5.0, dogs: [%{id: 1000 + i, name: "X#{i}", days: 5}]}
      groups = [%{category: "Terrier", n: 500, median_days: 15.0, dogs: dogs} | other_groups]

      layout = ChartGeometry.beeswarm_layout(groups, nil)

      terrier_column = Enum.find(layout.columns, &(&1.category == "Terrier"))
      terrier_dots = Enum.filter(layout.dots, &(&1.category == "Terrier"))
      assert length(terrier_dots) == 500

      Enum.each(terrier_dots, fn dot ->
        assert_in_delta dot.x, terrier_column.x, 30
      end)
    end

    test "spreads dots wider within wider columns instead of a fixed pixel amount" do
      # All 200 dogs share the exact same days value, so they land in one
      # y-band together. That's needed to actually saturate the jitter
      # spread toward the column's full magnitude instead of being capped
      # by the flat per-dot @jitter_step.
      dogs = for i <- 1..200, do: %{id: i, name: "Dog#{i}", days: 5}
      groups = [%{category: "Male", n: 200, median_days: 5.0, dogs: dogs}]

      layout = ChartGeometry.beeswarm_layout(groups, nil)

      column_x = hd(layout.columns).x
      max_offset = layout.dots |> Enum.map(&abs(&1.x - column_x)) |> Enum.max()

      # Single group -> column_width = max(60, 900/1) = 900, so the spread
      # should use much more than the old fixed 25px cap.
      assert max_offset > 100
    end

    test "y_ticks only includes candidate values within the actual days range" do
      groups = [%{category: "Beagle", n: 2, median_days: 20.0, dogs: [%{id: 1, name: "A", days: 5}, %{id: 2, name: "B", days: 40}]}]

      layout = ChartGeometry.beeswarm_layout(groups, nil)

      labels = Enum.map(layout.y_ticks, & &1.label)
      assert labels == ["7d", "30d"]
    end
  end

  describe "scatter_layout/2" do
    test "returns an empty layout for no points" do
      assert ChartGeometry.scatter_layout([], nil) == %{
               width: 600,
               height: 400,
               dots: [],
               reference_y: nil,
               reference_days: nil,
               plot_left: 50,
               axis_center_y: 200.0,
               y_ticks: [],
               x_axis_y: 380,
               x_ticks: []
             }
    end

    test "x_ticks only includes candidate values within the actual value range" do
      points = [%{id: 1, name: "A", value: 5, days: 10}, %{id: 2, name: "B", value: 50, days: 20}]

      layout = ChartGeometry.scatter_layout(points, nil, x_tick_candidates: [0, 10, 25, 50, 75, 100])

      labels = Enum.map(layout.x_ticks, & &1.label)
      assert labels == ["10", "25", "50"]
    end

    test "x_tick_label option overrides the default label formatting" do
      points = [%{id: 1, name: "A", value: 0, days: 10}, %{id: 2, name: "B", value: 120, days: 20}]

      label_fn = fn months when months <= 12 -> "#{trunc(months)}m"
                   months -> "#{round(months / 12)}y"
                 end

      layout =
        ChartGeometry.scatter_layout(points, nil,
          x_tick_candidates: [0, 6, 12, 24, 60, 120],
          x_tick_label: label_fn
        )

      labels = Enum.map(layout.x_ticks, & &1.label)
      assert labels == ["0m", "6m", "12m", "2y", "5y", "10y"]
    end

    test "places one dot per point, carrying id/name, and computes a reference line" do
      points = [
        %{id: 1, name: "Fido", value: 12, days: 5},
        %{id: 2, name: "Rex", value: 36, days: 25}
      ]

      layout = ChartGeometry.scatter_layout(points, 10.0)

      assert [%{id: 1, name: "Fido"}, %{id: 2, name: "Rex"}] = layout.dots
      assert is_float(layout.reference_y)
    end

    test "each dot carries its value and days for the tooltip" do
      points = [%{id: 1, name: "Fido", value: 24, days: 9}]

      layout = ChartGeometry.scatter_layout(points, nil)

      assert [%{value: 24, days: 9}] = layout.dots
    end
  end
end
