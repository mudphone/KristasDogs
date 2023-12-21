defmodule KristasDogs.Houses do
  @moduledoc """
  The Houses context.
  """

  import Ecto.Query, warn: false
  alias KristasDogs.Repo

  alias KristasDogs.Houses.Pet

  @archive_page_size 100

  def archive_page_size, do: @archive_page_size

  @doc """
  Returns the list of pets.

  ## Examples

      iex> list_pets()
      [%Pet{}, ...]

  """
  def list_pets do
    Repo.all(Pet)
  end

  def list_shown_dogs do
    species = Pet.species(:dog)
    Pet
    |> where([p], p.species == ^species)
    |> order_by([p], [desc: p.inserted_at])
    |> where([p], is_nil(p.removed_from_website_at))
    |> preload([p], [:pet_images])
    |> Repo.all()
  end

  def list_archived_dogs(page \\ 1) do
    species = Pet.species(:dog)
    offset = @archive_page_size * (page - 1)
    q =
      from p in Pet,
        where: p.species == ^species
           and not is_nil(p.removed_from_website_at),
        order_by: [desc: p.removed_from_website_at],
        limit: @archive_page_size,
        offset: ^offset,
        preload: [:pet_images]
    Repo.all(q)
  end

  def list_available_dogs_without_details() do
    checked_since =
      DateTime.utc_now()
      |> DateTime.add(-30, :day)
    species = Pet.species(:dog)
    q =
      from p in Pet,
      where: p.species == ^species
          and is_nil(p.removed_from_website_at)
          and is_nil(p.details_added_at)
          and (is_nil(p.details_checked_at)
               or p.details_checked_at <= ^checked_since)
    q |> Repo.all()
  end

  def count_dogs(archived?) do
    q =
      from p in Pet,
        where: p.species == "dog",
        select: count(p.id)
    q =
      if archived? do
        q |> where([p], not is_nil(p.removed_from_website_at))
      else
        q |> where([p], is_nil(p.removed_from_website_at))
      end
    Repo.one(q)
  end

  def count_shown_dogs() do
    archived? = false
    count_dogs(archived?)
  end

  def count_archived_dogs() do
    archived? = true
    count_dogs(archived?)
  end

  # Exact match
  # def search_dogs(name, archived?) do
  #   name = String.downcase(name)

  #   q =
  #     Pet
  #     |> where([p], p.species == "dog")
  #     |> where([p], fragment("lower(?)", p.name) == ^name)
  #     |> order_by([p], [desc: p.inserted_at])
  #   q =
  #     if archived? do
  #       q |> where([p], not is_nil(p.removed_from_website_at))
  #     else
  #       q |> where([p], is_nil(p.removed_from_website_at))
  #     end
  #   Repo.all(q)
  # end

  def search_shown_dogs(""), do: list_shown_dogs()
  def search_shown_dogs(search_name) do
    search_name = String.downcase(search_name)
    list_shown_dogs()
    |> Enum.filter(fn dog ->
      dog_name = String.downcase(dog.name)
      String.jaro_distance(dog_name, search_name) >= 0.8
        or String.starts_with?(dog_name, search_name)
    end)
  end

  def search_archived_dogs("", %{page: page}), do: list_archived_dogs(page)
  def search_archived_dogs(search_name, _) do
    # Note: SQLite `like` is case insensitive by default
    search_term = "%#{search_name}%"
    q =
      from p in Pet,
        where: p.species == "dog"
           and not is_nil(p.removed_from_website_at)
           and like(p.name, ^search_term),
        order_by: [desc: p.inserted_at],
        preload: [:pet_images]
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

  def unremove_dog(pet_id) do
    from(p in Pet,
      where: not is_nil(p.removed_from_website_at)
        and p.id == ^pet_id,
      update: [set: [removed_from_website_at: nil]]
    )
    |> Repo.update_all([])
  end

  def ensure_available_dog(%Pet{id: id, removed_from_website_at: removed_at}) do
    if removed_at do
      unremove_dog(id)
    end
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

  def is_male?(%Pet{gender: gender}), do: String.downcase(gender) == "male"
  def is_female?(%Pet{gender: gender}), do: String.downcase(gender) == "female"

  def minutes_since_added(%Pet{inserted_at: inserted_at}) do
    now = DateTime.utc_now()
    DateTime.diff(now, inserted_at, :minute)
  end
end
