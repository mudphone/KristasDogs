defmodule KristasDogs.Houses.Pet do
  use Ecto.Schema
  import Ecto.Changeset

  alias KristasDogs.PetDetails.PetImage
  alias KristasDogs.Houses.PetNormalization

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
    field :normal_primary_breed, :string
    field :normal_age_months, :integer
    field :normal_weight_lbs, :float
    field :removed_from_website_at, :utc_datetime, default: nil

    field :description, :string
    field :size, :string
    field :weight, :string
    field :altered, :boolean
    field :details_added_at, :utc_datetime
    field :details_checked_at, :utc_datetime

    has_many :pet_images, PetImage

    timestamps(type: :utc_datetime)
  end

  def species(:dog), do: "dog"

  @doc false
  def changeset(pet, attrs) do
    pet
    |> cast(attrs, [:name, :data_id, :age_text, :gender, :primary_breed, :species, :title, :campus, :location, :details_url, :profile_image_url])
    |> validate_required([:name, :data_id, :details_url, :profile_image_url])
    |> put_normalized_breed_and_age()
  end

  def changeset_details(pet, attrs) do
    pet
    |> cast(attrs, [:description, :size, :weight, :altered, :details_added_at])
    |> validate_required([:size, :weight, :altered, :details_added_at])
    |> put_normalized_weight()
  end

  def changeset_details_checked_at(pet, attrs) do
    pet
    |> cast(attrs, [:details_checked_at])
    |> validate_required([:details_checked_at])
  end

  defp put_normalized_breed_and_age(changeset) do
    changeset
    |> put_change(:normal_primary_breed, PetNormalization.normalize_primary_breed(get_field(changeset, :primary_breed)))
    |> put_change(:normal_age_months, PetNormalization.normalize_age_months(get_field(changeset, :age_text)))
  end

  defp put_normalized_weight(changeset) do
    put_change(changeset, :normal_weight_lbs, PetNormalization.normalize_weight_lbs(get_field(changeset, :weight)))
  end
end
