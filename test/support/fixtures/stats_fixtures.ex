defmodule KristasDogs.StatsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `KristasDogs.Stats` context.
  """

  @doc """
  Generate a pet_count.
  """
  def pet_count_fixture(attrs \\ %{}) do
    {:ok, pet_count} =
      attrs
      |> Enum.into(%{
        count: 42,
        counter_type: "some counter_type"
      })
      |> KristasDogs.Stats.create_pet_count()

    pet_count
  end
end
