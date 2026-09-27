defmodule Mix.Tasks.BackfillNormalizedPetFields do
  @moduledoc """
  One-time backfill of normal_primary_breed, normal_age_months, and
  normal_weight_lbs for every existing pet row, using the same rules
  `KristasDogs.Houses.Pet.changeset/2` and `changeset_details/2` apply
  automatically to new pets going forward.

      mix backfill_normalized_pet_fields
  """

  use Mix.Task

  alias KristasDogs.Repo
  alias KristasDogs.Houses.Pet
  alias KristasDogs.Houses.PetNormalization

  @shortdoc "Backfills normal_primary_breed/normal_age_months/normal_weight_lbs on existing pets"

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")
    call()
    Mix.shell().info("Backfill complete.")
  end

  @doc """
  Runs the backfill itself, separated from `run/1` so tests can call it
  directly without going through `Mix.Task.run("app.start")`, which
  doesn't play well with the Ecto SQL sandbox in tests.
  """
  def call do
    Repo.all(Pet)
    |> Enum.each(&backfill_pet/1)
  end

  defp backfill_pet(%Pet{} = pet) do
    pet
    |> Ecto.Changeset.change(
      normal_primary_breed: PetNormalization.normalize_primary_breed(pet.primary_breed),
      normal_age_months: PetNormalization.normalize_age_months(pet.age_text),
      normal_weight_lbs: PetNormalization.normalize_weight_lbs(pet.weight)
    )
    |> Repo.update!()
  end
end
