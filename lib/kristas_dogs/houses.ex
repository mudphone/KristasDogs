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

  # def list_dogs do
  #   q =
  #     from p in Pet,
  #       where: p.species == "dog",
  #       order_by: [desc: p.inserted_at]
  #   Repo.all(q)
  # end

  def list_dogs(archived?) do
    q =
      Pet
      |> where([p], p.species == "dog")
      |> order_by([p], [desc: p.inserted_at])
    if archived? do
      q |> where([p], not is_nil(p.removed_from_website_at))
    else
      q |> where([p], is_nil(p.removed_from_website_at))
    end
    |> Repo.all()
  end

  def list_shown_dogs do
    # q =
    #   from p in Pet,
    #     where: p.species == "dog"
    #        and is_nil(p.removed_from_website_at),
    #     order_by: [desc: p.inserted_at]
    # Repo.all(q)
    archived? = false
    list_dogs(archived?)
  end

  def list_archived_dogs(page \\ 1) do
    offset = @archive_page_size * (page - 1)
    q =
      from p in Pet,
        where: p.species == "dog"
           and not is_nil(p.removed_from_website_at),
        order_by: [desc: p.inserted_at],
        limit: @archive_page_size,
        offset: ^offset
    Repo.all(q)
    # archived? = true
    # list_dogs(archived?)
  end

  def count_archived_dogs() do
    q =
      from p in Pet,
        where: p.species == "dog"
           and not is_nil(p.removed_from_website_at),
        select: count(p.id)
    Repo.one(q)
  end

  def search_dogs("", archived?) do
    if archived?, do: list_archived_dogs(), else: list_shown_dogs()
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

  def search_dogs(search_name, archived?) do
    search_name = String.downcase(search_name)
    list_dogs(archived?)
    |> Enum.filter(fn dog ->
      dog_name = String.downcase(dog.name)
      String.jaro_distance(dog_name, search_name) >= 0.8
        or String.starts_with?(dog_name, search_name)
    end)
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
