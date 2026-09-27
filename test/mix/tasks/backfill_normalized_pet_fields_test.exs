defmodule Mix.Tasks.BackfillNormalizedPetFieldsTest do
  use KristasDogs.DataCase

  alias KristasDogs.Repo
  alias KristasDogs.Houses.Pet

  test "populates normalized columns for pets that predate the normalization logic" do
    pet =
      %Pet{}
      |> Ecto.Changeset.change(%{
        name: "Old Dog",
        data_id: "old-dog-1",
        details_url: "http://example.com",
        profile_image_url: "http://example.com/img.jpg",
        species: "dog",
        primary_breed: "Terrier, Jack Russell",
        age_text: "2 years old",
        weight: "40 lbs"
      })
      |> Repo.insert!()

    assert pet.normal_primary_breed == nil
    assert pet.normal_age_months == nil
    assert pet.normal_weight_lbs == nil

    Mix.Tasks.BackfillNormalizedPetFields.call()

    updated = Repo.get!(Pet, pet.id)
    assert updated.normal_primary_breed == "Jack Russell Terrier"
    assert updated.normal_age_months == 24
    assert updated.normal_weight_lbs == 40.0
  end

  test "leaves already-normalized pets unchanged" do
    pet =
      %Pet{}
      |> Ecto.Changeset.change(%{
        name: "New Dog",
        data_id: "new-dog-1",
        details_url: "http://example.com",
        profile_image_url: "http://example.com/img.jpg",
        species: "dog",
        primary_breed: "Affenpinscher",
        normal_primary_breed: "Affenpinscher"
      })
      |> Repo.insert!()

    Mix.Tasks.BackfillNormalizedPetFields.call()

    updated = Repo.get!(Pet, pet.id)
    assert updated.normal_primary_breed == "Affenpinscher"
  end
end
