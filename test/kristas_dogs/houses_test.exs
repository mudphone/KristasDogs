defmodule KristasDogs.HousesTest do
  use KristasDogs.DataCase

  alias KristasDogs.Houses

  describe "pets" do
    alias KristasDogs.Houses.Pet

    import KristasDogs.HousesFixtures

    @invalid_attrs %{name: nil, title: nil, location: nil, data_id: nil, age_text: nil, gender: nil, primary_breed: nil, species: nil, campus: nil, details_url: nil, profile_image_url: nil}

    test "list_pets/0 returns all pets" do
      pet = pet_fixture()
      assert Houses.list_pets() == [pet]
    end

    test "get_pet!/1 returns the pet with given id" do
      pet = pet_fixture()
      assert Houses.get_pet!(pet.id) == pet
    end

    test "create_pet/1 with valid data creates a pet" do
      valid_attrs = %{name: "some name", title: "some title", location: "some location", data_id: "some data_id", age_text: "some age_text", gender: "some gender", primary_breed: "some primary_breed", species: "some species", campus: "some campus", details_url: "some details_url", profile_image_url: "some profile_image_url"}

      assert {:ok, %Pet{} = pet} = Houses.create_pet(valid_attrs)
      assert pet.name == "some name"
      assert pet.title == "some title"
      assert pet.location == "some location"
      assert pet.data_id == "some data_id"
      assert pet.age_text == "some age_text"
      assert pet.gender == "some gender"
      assert pet.primary_breed == "some primary_breed"
      assert pet.species == "some species"
      assert pet.campus == "some campus"
      assert pet.details_url == "some details_url"
      assert pet.profile_image_url == "some profile_image_url"
    end

    test "create_pet/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Houses.create_pet(@invalid_attrs)
    end

    test "update_pet/2 with valid data updates the pet" do
      pet = pet_fixture()
      update_attrs = %{name: "some updated name", title: "some updated title", location: "some updated location", data_id: "some updated data_id", age_text: "some updated age_text", gender: "some updated gender", primary_breed: "some updated primary_breed", species: "some updated species", campus: "some updated campus", details_url: "some updated details_url", profile_image_url: "some updated profile_image_url"}

      assert {:ok, %Pet{} = pet} = Houses.update_pet(pet, update_attrs)
      assert pet.name == "some updated name"
      assert pet.title == "some updated title"
      assert pet.location == "some updated location"
      assert pet.data_id == "some updated data_id"
      assert pet.age_text == "some updated age_text"
      assert pet.gender == "some updated gender"
      assert pet.primary_breed == "some updated primary_breed"
      assert pet.species == "some updated species"
      assert pet.campus == "some updated campus"
      assert pet.details_url == "some updated details_url"
      assert pet.profile_image_url == "some updated profile_image_url"
    end

    test "update_pet/2 with invalid data returns error changeset" do
      pet = pet_fixture()
      assert {:error, %Ecto.Changeset{}} = Houses.update_pet(pet, @invalid_attrs)
      assert pet == Houses.get_pet!(pet.id)
    end

    test "delete_pet/1 deletes the pet" do
      pet = pet_fixture()
      assert {:ok, %Pet{}} = Houses.delete_pet(pet)
      assert_raise Ecto.NoResultsError, fn -> Houses.get_pet!(pet.id) end
    end

    test "change_pet/1 returns a pet changeset" do
      pet = pet_fixture()
      assert %Ecto.Changeset{} = Houses.change_pet(pet)
    end

    test "create_pet/1 computes normal_primary_breed and normal_age_months" do
      attrs = %{
        name: "Wednesday",
        title: "some title",
        location: "some location",
        data_id: "some data_id",
        age_text: "2 years old",
        gender: "Female",
        primary_breed: "Terrier, Jack Russell",
        species: "dog",
        campus: "some campus",
        details_url: "some details_url",
        profile_image_url: "some profile_image_url"
      }

      assert {:ok, %Pet{} = pet} = Houses.create_pet(attrs)
      assert pet.normal_primary_breed == "Jack Russell Terrier"
      assert pet.normal_age_months == 24
    end

    test "create_pet/1 leaves normal_age_months nil for unparseable age_text" do
      assert {:ok, %Pet{} = pet} = Houses.create_pet(%{name: "n", data_id: "d", details_url: "u", profile_image_url: "p", age_text: "some age_text"})
      assert pet.normal_age_months == nil
    end

    test "update_removed_dogs/1 sets removed_from_website_at and bumps updated_at for pets no longer seen" do
      pet = pet_fixture()
      pet |> change(updated_at: ~U[2025-01-01 00:00:00Z]) |> Repo.update!()

      Houses.update_removed_dogs([])

      updated = Houses.get_pet!(pet.id)
      assert updated.removed_from_website_at != nil
      assert updated.updated_at != ~U[2025-01-01 00:00:00Z]
    end

    test "update_removed_dogs/1 leaves updated_at unchanged for pets still seen" do
      pet = pet_fixture()
      pet |> change(updated_at: ~U[2025-01-01 00:00:00Z]) |> Repo.update!()

      Houses.update_removed_dogs([pet.id])

      updated = Houses.get_pet!(pet.id)
      assert updated.removed_from_website_at == nil
      assert updated.updated_at == ~U[2025-01-01 00:00:00Z]
    end

    test "unremove_dog/1 clears removed_from_website_at and bumps updated_at" do
      pet = pet_fixture()
      Houses.update_removed_dogs([])
      pet |> change(updated_at: ~U[2025-01-01 00:00:00Z]) |> Repo.update!()

      Houses.unremove_dog(pet.id)

      updated = Houses.get_pet!(pet.id)
      assert updated.removed_from_website_at == nil
      assert updated.updated_at != ~U[2025-01-01 00:00:00Z]
    end
  end
end
