defmodule KristasDogs.DogStatsFixtures do
  @moduledoc """
  Test helper for creating fully-controlled "adopted dog" rows for
  KristasDogs.DogStats tests. Bypasses Pet.changeset/2 and
  Pet.changeset_details/2 so tests can set inserted_at,
  removed_from_website_at, and normalized columns directly.
  """

  alias KristasDogs.Repo
  alias KristasDogs.Houses.Pet

  def adopted_dog_fixture(attrs \\ %{}) do
    defaults = %{
      name: "Fixture Dog",
      data_id: "fixture-dog-#{System.unique_integer([:positive])}",
      details_url: "http://example.com",
      profile_image_url: "http://example.com/image.jpg",
      species: "dog",
      gender: "Male",
      size: "Medium",
      primary_breed: "Terrier",
      normal_primary_breed: "Terrier",
      age_text: "2 years old",
      normal_age_months: 24,
      weight: "40 lbs",
      normal_weight_lbs: 40.0,
      inserted_at: ~U[2024-01-01 00:00:00Z],
      updated_at: ~U[2024-01-01 00:00:00Z],
      removed_from_website_at: ~U[2024-01-11 00:00:00Z]
    }

    attrs = Map.merge(defaults, Map.new(attrs))

    %Pet{}
    |> Ecto.Changeset.change(attrs)
    |> Repo.insert!()
  end
end
