defmodule KristasDogs.StatsTest do
  use KristasDogs.DataCase

  alias KristasDogs.Stats

  describe "pet_counts" do
    alias KristasDogs.Stats.PetCount

    import KristasDogs.StatsFixtures

    @invalid_attrs %{count: nil, counter_type: nil}

    test "list_pet_counts/0 returns all pet_counts" do
      pet_count = pet_count_fixture()
      assert Stats.list_pet_counts() == [pet_count]
    end

    test "get_pet_count!/1 returns the pet_count with given id" do
      pet_count = pet_count_fixture()
      assert Stats.get_pet_count!(pet_count.id) == pet_count
    end

    test "create_pet_count/1 with valid data creates a pet_count" do
      valid_attrs = %{count: 42, counter_type: "some counter_type"}

      assert {:ok, %PetCount{} = pet_count} = Stats.create_pet_count(valid_attrs)
      assert pet_count.count == 42
      assert pet_count.counter_type == "some counter_type"
    end

    test "create_pet_count/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Stats.create_pet_count(@invalid_attrs)
    end

    test "update_pet_count/2 with valid data updates the pet_count" do
      pet_count = pet_count_fixture()
      update_attrs = %{count: 43, counter_type: "some updated counter_type"}

      assert {:ok, %PetCount{} = pet_count} = Stats.update_pet_count(pet_count, update_attrs)
      assert pet_count.count == 43
      assert pet_count.counter_type == "some updated counter_type"
    end

    test "update_pet_count/2 with invalid data returns error changeset" do
      pet_count = pet_count_fixture()
      assert {:error, %Ecto.Changeset{}} = Stats.update_pet_count(pet_count, @invalid_attrs)
      assert pet_count == Stats.get_pet_count!(pet_count.id)
    end

    test "delete_pet_count/1 deletes the pet_count" do
      pet_count = pet_count_fixture()
      assert {:ok, %PetCount{}} = Stats.delete_pet_count(pet_count)
      assert_raise Ecto.NoResultsError, fn -> Stats.get_pet_count!(pet_count.id) end
    end

    test "change_pet_count/1 returns a pet_count changeset" do
      pet_count = pet_count_fixture()
      assert %Ecto.Changeset{} = Stats.change_pet_count(pet_count)
    end
  end
end
