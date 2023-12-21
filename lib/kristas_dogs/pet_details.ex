defmodule KristasDogs.PetDetails do
  @moduledoc """
  The PetDetails context.
  """

  import Ecto.Query, warn: false
  alias KristasDogs.Repo

  alias KristasDogs.Houses.Pet
  alias KristasDogs.PetDetails.PetImage

  @doc """
  Returns the list of pet_images.

  ## Examples

      iex> list_pet_images()
      [%PetImage{}, ...]

  """
  def list_pet_images do
    Repo.all(PetImage)
  end

  @doc """
  Gets a single pet_image.

  Raises `Ecto.NoResultsError` if the Pet image does not exist.

  ## Examples

      iex> get_pet_image!(123)
      %PetImage{}

      iex> get_pet_image!(456)
      ** (Ecto.NoResultsError)

  """
  def get_pet_image!(id), do: Repo.get!(PetImage, id)

  @doc """
  Creates a pet_image.

  ## Examples

      iex> create_pet_image(%{field: value})
      {:ok, %PetImage{}}

      iex> create_pet_image(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_pet_image(attrs \\ %{}) do
    %PetImage{}
    |> PetImage.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a pet_image.

  ## Examples

      iex> update_pet_image(pet_image, %{field: new_value})
      {:ok, %PetImage{}}

      iex> update_pet_image(pet_image, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_pet_image(%PetImage{} = pet_image, attrs) do
    pet_image
    |> PetImage.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a pet_image.

  ## Examples

      iex> delete_pet_image(pet_image)
      {:ok, %PetImage{}}

      iex> delete_pet_image(pet_image)
      {:error, %Ecto.Changeset{}}

  """
  def delete_pet_image(%PetImage{} = pet_image) do
    Repo.delete(pet_image)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking pet_image changes.

  ## Examples

      iex> change_pet_image(pet_image)
      %Ecto.Changeset{data: %PetImage{}}

  """
  def change_pet_image(%PetImage{} = pet_image, attrs \\ %{}) do
    PetImage.changeset(pet_image, attrs)
  end

    @doc """
  Updates a pet's details.

  ## Examples

      iex> update_pet_details(pet, %{field: new_value})
      {:ok, %Pet{}}

      iex> update_pet_details(pet, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_pet_details(%Pet{} = pet, attrs) do
    attrs =
      attrs
      |> Map.put(:details_added_at, DateTime.utc_now())
      |> Map.put(:details_checked_at, DateTime.utc_now())
    pet
    |> Pet.changeset_details(attrs)
    |> Repo.update()
  end

  def update_pet_details_checked(%Pet{} = pet) do
    attrs =
      %{details_checked_at: DateTime.utc_now()}
    pet
    |> Pet.changeset_details_checked_at(attrs)
    |> Repo.update()
  end
end
