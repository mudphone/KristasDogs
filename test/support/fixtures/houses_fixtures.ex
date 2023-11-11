defmodule KristasDogs.HousesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `KristasDogs.Houses` context.
  """

  @doc """
  Generate a pet.
  """
  def pet_fixture(attrs \\ %{}) do
    {:ok, pet} =
      attrs
      |> Enum.into(%{
        age_text: "some age_text",
        campus: "some campus",
        data_id: "some data_id",
        details_url: "some details_url",
        gender: "some gender",
        location: "some location",
        name: "some name",
        primary_breed: "some primary_breed",
        profile_image_url: "some profile_image_url",
        species: "some species",
        title: "some title"
      })
      |> KristasDogs.Houses.create_pet()

    pet
  end
end
