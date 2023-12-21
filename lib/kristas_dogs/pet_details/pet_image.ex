defmodule KristasDogs.PetDetails.PetImage do
  use Ecto.Schema
  import Ecto.Changeset

  alias KristasDogs.Houses.Pet

  schema "pet_images" do
    field :url, :string

    belongs_to :pet, Pet

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(pet_image, attrs) do
    pet_image
    |> cast(attrs, [:url, :pet_id])
    |> validate_required([:url, :pet_id])
  end
end
