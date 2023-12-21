defmodule KristasDogs.PetDetailsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `KristasDogs.PetDetails` context.
  """

  @doc """
  Generate a pet_image.
  """
  def pet_image_fixture(attrs \\ %{}) do
    {:ok, pet_image} =
      attrs
      |> Enum.into(%{
        url: "some url"
      })
      |> KristasDogs.PetDetails.create_pet_image()

    pet_image
  end
end
