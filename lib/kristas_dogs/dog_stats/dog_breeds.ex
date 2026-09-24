defmodule KristasDogs.DogStats.DogBreeds do
  import Ecto.Query, warn: false

  alias KristasDogs.Repo
  alias KristasDogs.Houses.Pet

  def distinct_breeds do
    q =
      from p in Pet,
        select: p.primary_breed,
        distinct: true,
        where: p.species == "dog"

    q |> Repo.all()
  end
end
