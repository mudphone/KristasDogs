defmodule KristasDogs.DogStats do
  @moduledoc """
  Adoption-time statistics: how long dogs take to be adopted, broken down
  by breed, age, gender, size, and weight. See
  docs/superpowers/specs/2026-09-24-adoption-time-stats-design.md for the
  full design.
  """

  import Ecto.Query, warn: false

  alias KristasDogs.Repo
  alias KristasDogs.Houses.Pet

  # Before this cutoff, Fly.io could scale the app to zero when idle, so
  # scraper timing was unreliable and older dogs' timestamps aren't
  # trustworthy for duration math.
  @data_quality_cutoff ~U[2025-06-30 01:12:49Z]

  @doc """
  The shelter-wide median days-to-adoption across all adopted dogs (dogs
  with a non-nil removed_from_website_at). Returns nil if there are none.
  """
  def overall_median_days do
    adopted_dogs_query()
    |> select([p], {p.inserted_at, p.removed_from_website_at})
    |> Repo.all()
    |> Enum.map(fn {inserted_at, removed_at} -> days_between(inserted_at, removed_at) end)
    |> median()
  end

  @doc """
  Days-to-adoption grouped by normalized primary breed, sorted ascending
  by median days (fastest-adopted first). Excludes dogs with no
  normalized breed.
  """
  def breed_groups do
    adopted_dogs_query()
    |> where([p], not is_nil(p.normal_primary_breed))
    |> select([p], {p.normal_primary_breed, p.id, p.name, p.inserted_at, p.removed_from_website_at})
    |> Repo.all()
    |> group_by_category()
  end

  @doc """
  Days-to-adoption grouped by size, sorted ascending by median days.
  Excludes dogs with a blank size.
  """
  def size_groups do
    adopted_dogs_query()
    |> where([p], not is_nil(p.size) and p.size != "")
    |> select([p], {p.size, p.id, p.name, p.inserted_at, p.removed_from_website_at})
    |> Repo.all()
    |> group_by_category()
  end

  @doc """
  Days-to-adoption grouped by gender, sorted ascending by median days.
  """
  def gender_groups do
    adopted_dogs_query()
    |> where([p], not is_nil(p.gender) and p.gender != "")
    |> select([p], {p.gender, p.id, p.name, p.inserted_at, p.removed_from_website_at})
    |> Repo.all()
    |> group_by_category()
  end

  @doc """
  Median of a list of numbers, as a float. Returns nil for an empty list.
  """
  def median([]), do: nil

  def median(values) do
    sorted = Enum.sort(values)
    count = length(sorted)
    mid = div(count, 2)

    if rem(count, 2) == 0 do
      (Enum.at(sorted, mid - 1) + Enum.at(sorted, mid)) / 2
    else
      Enum.at(sorted, mid) * 1.0
    end
  end

  defp adopted_dogs_query do
    species = Pet.species(:dog)

    from p in Pet,
      where:
        p.species == ^species and not is_nil(p.removed_from_website_at) and
          p.inserted_at >= ^@data_quality_cutoff
  end

  defp days_between(inserted_at, removed_at) do
    DateTime.diff(removed_at, inserted_at, :day)
  end

  @doc """
  One `%{id: id, name: name, value: months, days: days}` entry per
  adopted dog with a known age, for the age-vs-days-to-adoption
  scatterplot. `id`/`name` are carried through for the hover tooltip.
  """
  def age_points do
    adopted_dogs_query()
    |> where([p], not is_nil(p.normal_age_months))
    |> select([p], {p.id, p.name, p.normal_age_months, p.inserted_at, p.removed_from_website_at})
    |> Repo.all()
    |> Enum.map(fn {id, name, months, inserted_at, removed_at} ->
      %{id: id, name: name, value: months, days: days_between(inserted_at, removed_at)}
    end)
  end

  @doc """
  One `%{id: id, name: name, value: lbs, days: days}` entry per adopted
  dog with a known weight, for the weight-vs-days-to-adoption
  scatterplot. `id`/`name` are carried through for the hover tooltip.
  """
  def weight_points do
    adopted_dogs_query()
    |> where([p], not is_nil(p.normal_weight_lbs))
    |> select([p], {p.id, p.name, p.normal_weight_lbs, p.inserted_at, p.removed_from_website_at})
    |> Repo.all()
    |> Enum.map(fn {id, name, lbs, inserted_at, removed_at} ->
      %{id: id, name: name, value: lbs, days: days_between(inserted_at, removed_at)}
    end)
  end

  defp group_by_category(rows) do
    rows
    |> Enum.map(fn {category, id, name, inserted_at, removed_at} ->
      {category, %{id: id, name: name, days: days_between(inserted_at, removed_at)}}
    end)
    |> Enum.group_by(fn {category, _dog} -> category end, fn {_category, dog} -> dog end)
    |> Enum.map(fn {category, dogs} ->
      %{
        category: category,
        n: length(dogs),
        median_days: dogs |> Enum.map(& &1.days) |> median(),
        dogs: dogs
      }
    end)
    |> Enum.sort_by(& &1.median_days)
  end
end
