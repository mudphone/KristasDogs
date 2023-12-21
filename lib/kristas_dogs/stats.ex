defmodule KristasDogs.Stats do
  @moduledoc """
  The Stats context.
  """

  import Ecto.Query, warn: false
  alias KristasDogs.Repo
  require Logger

  # alias KristasDogs.Houses
  alias KristasDogs.Houses.Pet
  alias KristasDogs.Stats.PetCount

  @doc """
  Returns the list of pet_counts.

  ## Examples

      iex> list_pet_counts()
      [%PetCount{}, ...]

  """
  def list_pet_counts do
    Repo.all(PetCount)
  end

  def list_latest_pet_counts do
    two_weeks_ago =
      NaiveDateTime.utc_now()
      |> DateTime.from_naive!("Etc/UTC")
      |> DateTime.add(-30, :day)
    q =
      from p in PetCount,
        where: p.count_at >= ^two_weeks_ago,
        order_by: [asc: p.count_at]
    results =
      q
      |> Repo.all()
    results
  end

  @doc """
  Gets a single pet_count.

  Raises `Ecto.NoResultsError` if the Pet count does not exist.

  ## Examples

      iex> get_pet_count!(123)
      %PetCount{}

      iex> get_pet_count!(456)
      ** (Ecto.NoResultsError)

  """
  def get_pet_count!(id), do: Repo.get!(PetCount, id)

  @doc """
  Creates a pet_count.

  ## Examples

      iex> create_pet_count(%{field: value})
      {:ok, %PetCount{}}

      iex> create_pet_count(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_pet_count(attrs \\ %{}) do
    %PetCount{}
    |> PetCount.changeset(attrs)
    |> Repo.insert()
  end

  defp get_last_dog_count_rec() do
    type = PetCount.counter_type_dogs_available()
    q =
      from c in PetCount,
        where: c.counter_type == ^type,
        order_by: [desc: c.count_at],
        limit: 1
    Repo.one(q)
  end

  defp get_first_dog_rec() do
    species = Pet.species(:dog)
    q =
      from p in Pet,
        where: p.species == ^species,
        order_by: [asc: p.inserted_at],
        limit: 1
    Repo.one(q)
  end

  def fill_all_counts() do
    next_utc = get_next_count_date_utc()
    unless is_nil(next_utc) do
      fill_counts(next_utc)
    end
    Logger.info("Filling counts complete.")
  end

  defp fill_counts(next_utc) do
    if DateTime.before?(next_utc, DateTime.utc_now()) do
      Logger.info("Adding count for day: #{next_utc}")
      {:ok, _} =
        %{
          counter_type: PetCount.counter_type_dogs_available(),
          count: dog_count_for_day(next_utc),
          count_at: next_utc
        }
        |> create_pet_count()
      # recur next day
      fill_counts(next_utc |> add_day())
    else
      Logger.info("Next count time is in the future.")
    end
  end

  defp tz(), do: Application.get_env(:kristas_dogs, :time)[:time_zone]

  defp to_local(dt) do
    {:ok, local} = DateTime.shift_zone(dt, tz())
    local
  end

  defp to_utc(dt) do
    {:ok, utc} = DateTime.shift_zone(dt, "Etc/UTC")
    utc
  end

  defp add_day(dt), do: DateTime.add(dt, 1, :day)

  defp stat_time(dt) do
    date = DateTime.to_date(dt)
    {:ok, time} = Time.new(23, 0, 0, 0)
    {:ok, dt} = DateTime.new(date, time, tz())
    dt
  end

  defp dog_count_for_day(eod_utc) do
    species = Pet.species(:dog)
    q =
      from p in Pet,
        select: count(p.id),
        where: p.species == ^species
            and p.inserted_at <= ^eod_utc
            and (is_nil(p.removed_from_website_at)
                or p.removed_from_website_at > ^eod_utc)
    Repo.one(q)
  end

  def get_next_count_date_utc() do
    case get_last_dog_count_rec() do
      %PetCount{count_at: count_at} ->
        Logger.info("Taking new count after last count: #{inspect count_at}")
        count_at
        |> to_local()
        |> add_day()
        |> stat_time()
        |> to_utc()
      nil ->
        case get_first_dog_rec() do
          %Pet{inserted_at: inserted_at} ->
            # no counts yet, so start on first day (first pet)
            Logger.info("No counts yet, starting after first pet: #{inspect inserted_at}")
            inserted_at
            |> to_local()
            |> stat_time()
            |> to_utc()
          nil ->
            Logger.info("No pets yet, counting will have to wait.")
            nil
        end
    end
  end


  @doc """
  Updates a pet_count.

  ## Examples

      iex> update_pet_count(pet_count, %{field: new_value})
      {:ok, %PetCount{}}

      iex> update_pet_count(pet_count, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_pet_count(%PetCount{} = pet_count, attrs) do
    pet_count
    |> PetCount.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a pet_count.

  ## Examples

      iex> delete_pet_count(pet_count)
      {:ok, %PetCount{}}

      iex> delete_pet_count(pet_count)
      {:error, %Ecto.Changeset{}}

  """
  def delete_pet_count(%PetCount{} = pet_count) do
    Repo.delete(pet_count)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking pet_count changes.

  ## Examples

      iex> change_pet_count(pet_count)
      %Ecto.Changeset{data: %PetCount{}}

  """
  def change_pet_count(%PetCount{} = pet_count, attrs \\ %{}) do
    PetCount.changeset(pet_count, attrs)
  end
end
