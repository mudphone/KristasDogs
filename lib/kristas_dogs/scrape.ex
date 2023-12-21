defmodule KristasDogs.Scrape do
  require Logger

  alias KristasDogs.Houses
  alias KristasDogs.Houses.Pet
  alias KristasDogs.Scrape.Details
  alias KristasDogs.Scrape.Dogs

  def record_dogs(), do: Dogs.record_dogs()

  def record_details() do
    dogs = Houses.list_available_dogs_without_details()
    for {%Pet{} = dog, i} <- Enum.with_index(dogs) do
      if i > 0 do
        Logger.info("Sleeping before details request...")
        Process.sleep(details_sleep_millis())
      end
      Logger.info("Checking details for pet: #{dog.id}")
      Details.record_details(dog)
    end
    Logger.info("Done recording details")
  end

  defp details_sleep_millis, do: Enum.random(500..2000)
end
