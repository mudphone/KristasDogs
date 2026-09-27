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
               reference_y: nil
             }
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

      assert layout.width == 2 * 60
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
      groups = [%{category: "Terrier", n: 500, median_days: 15.0, dogs: dogs}]

      layout = ChartGeometry.beeswarm_layout(groups, nil)

      column_x = hd(layout.columns).x
      assert length(layout.dots) == 500

      Enum.each(layout.dots, fn dot ->
        assert_in_delta dot.x, column_x, 30
      end)
    end
  end

  describe "scatter_layout/2" do
    test "returns an empty layout for no points" do
      assert ChartGeometry.scatter_layout([], nil) == %{width: 600, height: 400, dots: [], reference_y: nil}
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
  end
end
