defmodule KristasDogs.DogStatsTest do
  use KristasDogs.DataCase

  alias KristasDogs.DogStats

  import KristasDogs.DogStatsFixtures

  describe "median/1" do
    test "returns nil for an empty list" do
      assert DogStats.median([]) == nil
    end

    test "returns the middle value for an odd-length list" do
      assert DogStats.median([1, 3, 2]) == 2.0
    end

    test "returns the average of the two middle values for an even-length list" do
      assert DogStats.median([1, 2, 3, 4]) == 2.5
    end
  end

  describe "overall_median_days/0" do
    test "returns nil when there are no adopted dogs" do
      assert DogStats.overall_median_days() == nil
    end

    test "computes the median days-to-adoption across all adopted dogs" do
      adopted_dog_fixture(%{
        inserted_at: ~U[2025-07-01 00:00:00Z],
        removed_from_website_at: ~U[2025-07-06 00:00:00Z]
      })

      adopted_dog_fixture(%{
        inserted_at: ~U[2025-07-01 00:00:00Z],
        removed_from_website_at: ~U[2025-07-21 00:00:00Z]
      })

      assert DogStats.overall_median_days() == 12.5
    end

    test "excludes dogs still listed (no removed_from_website_at)" do
      adopted_dog_fixture(%{
        inserted_at: ~U[2025-07-01 00:00:00Z],
        removed_from_website_at: ~U[2025-07-06 00:00:00Z]
      })

      adopted_dog_fixture(%{
        inserted_at: ~U[2025-07-01 00:00:00Z],
        removed_from_website_at: nil
      })

      assert DogStats.overall_median_days() == 5.0
    end

    test "excludes dogs inserted before the data-quality cutoff" do
      adopted_dog_fixture(%{
        inserted_at: ~U[2025-06-30 01:12:49Z],
        removed_from_website_at: ~U[2025-07-05 01:12:49Z]
      })

      adopted_dog_fixture(%{
        inserted_at: ~U[2025-06-29 00:00:00Z],
        removed_from_website_at: ~U[2025-08-28 00:00:00Z]
      })

      assert DogStats.overall_median_days() == 5.0
    end
  end

  describe "breed_groups/0" do
    test "groups by normal_primary_breed, sorted ascending by median days" do
      terrier =
        adopted_dog_fixture(%{
          normal_primary_breed: "Terrier",
          inserted_at: ~U[2025-07-01 00:00:00Z],
          removed_from_website_at: ~U[2025-07-21 00:00:00Z]
        })

      beagle =
        adopted_dog_fixture(%{
          normal_primary_breed: "Beagle",
          inserted_at: ~U[2025-07-01 00:00:00Z],
          removed_from_website_at: ~U[2025-07-06 00:00:00Z]
        })

      assert [
               %{category: "Beagle", n: 1, median_days: 5.0, dogs: [%{id: beagle_id, name: beagle_name, days: 5}]},
               %{category: "Terrier", n: 1, median_days: 20.0, dogs: [%{id: terrier_id, name: terrier_name, days: 20}]}
             ] = DogStats.breed_groups()

      assert beagle_id == beagle.id
      assert beagle_name == beagle.name
      assert terrier_id == terrier.id
      assert terrier_name == terrier.name
    end

    test "excludes dogs with no normalized breed" do
      adopted_dog_fixture(%{normal_primary_breed: nil})

      assert DogStats.breed_groups() == []
    end
  end

  describe "size_groups/0" do
    test "groups by size, excluding blank size" do
      dog =
        adopted_dog_fixture(%{
          size: "Small",
          inserted_at: ~U[2025-07-01 00:00:00Z],
          removed_from_website_at: ~U[2025-07-06 00:00:00Z]
        })

      adopted_dog_fixture(%{size: ""})

      assert [%{category: "Small", n: 1, median_days: 5.0, dogs: [%{id: id, name: name, days: 5}]}] =
               DogStats.size_groups()

      assert id == dog.id
      assert name == dog.name
    end

    test "orders by Small, Medium, Large, Extra-Large regardless of median days" do
      adopted_dog_fixture(%{
        size: "Large",
        inserted_at: ~U[2025-07-01 00:00:00Z],
        removed_from_website_at: ~U[2025-07-02 00:00:00Z]
      })

      adopted_dog_fixture(%{
        size: "Small",
        inserted_at: ~U[2025-07-01 00:00:00Z],
        removed_from_website_at: ~U[2025-08-01 00:00:00Z]
      })

      adopted_dog_fixture(%{
        size: "Extra-Large",
        inserted_at: ~U[2025-07-01 00:00:00Z],
        removed_from_website_at: ~U[2025-07-15 00:00:00Z]
      })

      adopted_dog_fixture(%{
        size: "Medium",
        inserted_at: ~U[2025-07-01 00:00:00Z],
        removed_from_website_at: ~U[2025-07-10 00:00:00Z]
      })

      categories = DogStats.size_groups() |> Enum.map(& &1.category)
      assert categories == ["Small", "Medium", "Large", "Extra-Large"]
    end
  end

  describe "gender_groups/0" do
    test "groups by gender" do
      dog =
        adopted_dog_fixture(%{
          gender: "Female",
          inserted_at: ~U[2025-07-01 00:00:00Z],
          removed_from_website_at: ~U[2025-07-06 00:00:00Z]
        })

      assert [%{category: "Female", n: 1, median_days: 5.0, dogs: [%{id: id, name: name, days: 5}]}] =
               DogStats.gender_groups()

      assert id == dog.id
      assert name == dog.name
    end
  end

  describe "age_points/0" do
    test "returns one point per dog with a known age" do
      dog =
        adopted_dog_fixture(%{
          normal_age_months: 24,
          inserted_at: ~U[2025-07-01 00:00:00Z],
          removed_from_website_at: ~U[2025-07-06 00:00:00Z]
        })

      adopted_dog_fixture(%{normal_age_months: nil})

      assert [%{id: id, name: name, value: 24, days: 5}] = DogStats.age_points()
      assert id == dog.id
      assert name == dog.name
    end
  end

  describe "weight_points/0" do
    test "returns one point per dog with a known weight" do
      dog =
        adopted_dog_fixture(%{
          normal_weight_lbs: 40.0,
          inserted_at: ~U[2025-07-01 00:00:00Z],
          removed_from_website_at: ~U[2025-07-06 00:00:00Z]
        })

      adopted_dog_fixture(%{normal_weight_lbs: nil})

      assert [%{id: id, name: name, value: 40.0, days: 5}] = DogStats.weight_points()
      assert id == dog.id
      assert name == dog.name
    end
  end
end
