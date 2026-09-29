defmodule Mix.Tasks.BackfillRemovedDogTimestampsTest do
  use KristasDogs.DataCase

  alias KristasDogs.Repo
  alias KristasDogs.Houses.Pet

  test "advances updated_at to removed_from_website_at when removal is more recent" do
    pet =
      %Pet{}
      |> Ecto.Changeset.change(%{
        name: "Stale Dog",
        data_id: "stale-dog-1",
        details_url: "http://example.com",
        profile_image_url: "http://example.com/img.jpg",
        species: "dog",
        updated_at: ~U[2025-07-01 00:00:00Z],
        removed_from_website_at: ~U[2025-07-11 00:00:00Z]
      })
      |> Repo.insert!()

    Mix.Tasks.BackfillRemovedDogTimestamps.call()

    updated = Repo.get!(Pet, pet.id)
    assert updated.updated_at == updated.removed_from_website_at
    assert updated.updated_at == ~U[2025-07-11 00:00:00Z]
  end

  test "leaves updated_at unchanged when it is already at or after removed_from_website_at" do
    pet =
      %Pet{}
      |> Ecto.Changeset.change(%{
        name: "Rescraped Dog",
        data_id: "rescraped-dog-1",
        details_url: "http://example.com",
        profile_image_url: "http://example.com/img.jpg",
        species: "dog",
        removed_from_website_at: ~U[2025-07-11 00:00:00Z],
        updated_at: ~U[2025-07-15 00:00:00Z]
      })
      |> Repo.insert!()

    Mix.Tasks.BackfillRemovedDogTimestamps.call()

    updated = Repo.get!(Pet, pet.id)
    assert updated.updated_at == ~U[2025-07-15 00:00:00Z]
  end

  test "leaves updated_at unchanged for a pet that was never removed" do
    pet =
      %Pet{}
      |> Ecto.Changeset.change(%{
        name: "Available Dog",
        data_id: "available-dog-1",
        details_url: "http://example.com",
        profile_image_url: "http://example.com/img.jpg",
        species: "dog",
        removed_from_website_at: nil,
        updated_at: ~U[2025-07-01 00:00:00Z]
      })
      |> Repo.insert!()

    Mix.Tasks.BackfillRemovedDogTimestamps.call()

    updated = Repo.get!(Pet, pet.id)
    assert updated.updated_at == ~U[2025-07-01 00:00:00Z]
  end
end
