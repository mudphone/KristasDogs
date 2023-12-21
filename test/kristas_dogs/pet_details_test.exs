defmodule KristasDogs.PetDetailsTest do
  use KristasDogs.DataCase

  alias KristasDogs.PetDetails

  describe "pet_images" do
    alias KristasDogs.PetDetails.PetImage

    import KristasDogs.PetDetailsFixtures

    @invalid_attrs %{url: nil}

    test "list_pet_images/0 returns all pet_images" do
      pet_image = pet_image_fixture()
      assert PetDetails.list_pet_images() == [pet_image]
    end

    test "get_pet_image!/1 returns the pet_image with given id" do
      pet_image = pet_image_fixture()
      assert PetDetails.get_pet_image!(pet_image.id) == pet_image
    end

    test "create_pet_image/1 with valid data creates a pet_image" do
      valid_attrs = %{url: "some url"}

      assert {:ok, %PetImage{} = pet_image} = PetDetails.create_pet_image(valid_attrs)
      assert pet_image.url == "some url"
    end

    test "create_pet_image/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = PetDetails.create_pet_image(@invalid_attrs)
    end

    test "update_pet_image/2 with valid data updates the pet_image" do
      pet_image = pet_image_fixture()
      update_attrs = %{url: "some updated url"}

      assert {:ok, %PetImage{} = pet_image} = PetDetails.update_pet_image(pet_image, update_attrs)
      assert pet_image.url == "some updated url"
    end

    test "update_pet_image/2 with invalid data returns error changeset" do
      pet_image = pet_image_fixture()
      assert {:error, %Ecto.Changeset{}} = PetDetails.update_pet_image(pet_image, @invalid_attrs)
      assert pet_image == PetDetails.get_pet_image!(pet_image.id)
    end

    test "delete_pet_image/1 deletes the pet_image" do
      pet_image = pet_image_fixture()
      assert {:ok, %PetImage{}} = PetDetails.delete_pet_image(pet_image)
      assert_raise Ecto.NoResultsError, fn -> PetDetails.get_pet_image!(pet_image.id) end
    end

    test "change_pet_image/1 returns a pet_image changeset" do
      pet_image = pet_image_fixture()
      assert %Ecto.Changeset{} = PetDetails.change_pet_image(pet_image)
    end
  end
end
