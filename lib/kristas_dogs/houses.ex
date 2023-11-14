defmodule KristasDogs.Houses do
  @moduledoc """
  The Houses context.
  """

  import Ecto.Query, warn: false
  alias KristasDogs.Repo

  alias KristasDogs.Houses.Pet

  @doc """
  Returns the list of pets.

  ## Examples

      iex> list_pets()
      [%Pet{}, ...]

  """
  def list_pets do
    Repo.all(Pet)
  end

  # def list_dogs do
  #   q =
  #     from p in Pet,
  #       where: p.species == "dog",
  #       order_by: [desc: p.inserted_at]
  #   Repo.all(q)
  # end

  def list_shown_dogs do
    q =
      from p in Pet,
        where: p.species == "dog"
           and is_nil(p.removed_from_website_at),
        order_by: [desc: p.inserted_at]
    Repo.all(q)
  end

  def list_archived_dogs do
    q =
      from p in Pet,
        where: p.species == "dog"
           and not is_nil(p.removed_from_website_at),
        order_by: [desc: p.inserted_at]
    Repo.all(q)
  end

  def update_removed_dogs(seen_ids) do
    now = DateTime.utc_now

    from(p in Pet,
      where: is_nil(p.removed_from_website_at)
        and p.id not in ^seen_ids,
      update: [set: [removed_from_website_at: ^now]]
    )
    |> Repo.update_all([])
  end

  @doc """
  Gets a single pet.

  Raises `Ecto.NoResultsError` if the Pet does not exist.

  ## Examples

      iex> get_pet!(123)
      %Pet{}

      iex> get_pet!(456)
      ** (Ecto.NoResultsError)

  """
  def get_pet!(id), do: Repo.get!(Pet, id)

  def get_pet_by_data_id(data_id) when is_nil(data_id), do: nil
  def get_pet_by_data_id(data_id) do
    q =
      from p in Pet,
        where: p.data_id == ^data_id
    Repo.one(q)
  end

  @doc """
  Creates a pet.

  ## Examples

      iex> create_pet(%{field: value})
      {:ok, %Pet{}}

      iex> create_pet(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_pet(attrs \\ %{}) do
    attrs =
      attrs
      |> Map.update(:species, nil, &String.downcase(&1))
    %Pet{}
    |> Pet.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a pet.

  ## Examples

      iex> update_pet(pet, %{field: new_value})
      {:ok, %Pet{}}

      iex> update_pet(pet, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_pet(%Pet{} = pet, attrs) do
    pet
    |> Pet.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a pet.

  ## Examples

      iex> delete_pet(pet)
      {:ok, %Pet{}}

      iex> delete_pet(pet)
      {:error, %Ecto.Changeset{}}

  """
  def delete_pet(%Pet{} = pet) do
    Repo.delete(pet)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking pet changes.

  ## Examples

      iex> change_pet(pet)
      %Ecto.Changeset{data: %Pet{}}

  """
  def change_pet(%Pet{} = pet, attrs \\ %{}) do
    Pet.changeset(pet, attrs)
  end
end
