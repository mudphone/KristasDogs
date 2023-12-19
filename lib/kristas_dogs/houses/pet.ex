defmodule KristasDogs.Houses.Pet do
  use Ecto.Schema
  import Ecto.Changeset

  schema "pets" do
    field :name, :string
    field :title, :string
    field :location, :string
    field :data_id, :string
    field :age_text, :string
    field :gender, :string
    field :primary_breed, :string
    field :species, :string
    field :campus, :string
    field :details_url, :string
    field :profile_image_url, :string
    field :removed_from_website_at, :utc_datetime, default: nil

    timestamps(type: :utc_datetime)
  end

  def species(:dog), do: "dog"

  @doc false
  def changeset(pet, attrs) do
    pet
    # |> cast(attrs, [:name, :data_id, :age_text, :gender, :primary_breed, :species, :title, :campus, :location, :details_url, :profile_image_url])
    |> cast(attrs, [:name, :data_id, :age_text, :gender, :primary_breed, :species, :title, :campus, :location, :details_url, :profile_image_url])
    |> validate_required([:name, :data_id, :details_url, :profile_image_url])
  end
end
