defmodule KristasDogs.Stats.PetCount do
  use Ecto.Schema
  import Ecto.Changeset

  schema "pet_counts" do
    field :count, :integer
    field :counter_type, :string
    field :count_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @dogs_available "dogs_available"
  def counter_type_dogs_available, do: @dogs_available

  @doc false
  def changeset(pet_count, attrs) do
    pet_count
    |> cast(attrs, [:counter_type, :count, :count_at])
    |> validate_required([:counter_type, :count, :count_at])
  end
end
