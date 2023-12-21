defmodule KristasDogs.Scrape.Dogs do
  require Logger

  alias KristasDogs.Houses
  alias KristasDogs.Scrape.Utils

  @dogs_url "https://hawaiianhumane.org/adoptions/available-animals/?speciesID=1"

  def record_dogs() do
    get_dogs()
    |> process_dogs()
  end

  defp process_dogs(nil), do: Logger.warning("No dogs returned from scrape.")
  defp process_dogs(dogs) do
    pets =
      dogs
      |> Enum.map(fn dog ->
        data_id = Map.get(dog, "data-id")
        case Houses.get_pet_by_data_id(data_id) do
          nil ->
            Logger.info("create dog #{Map.get(dog, "data-name")}")
            result =
              %{
                name: Map.get(dog, "data-name"),
                title: Map.get(dog, "data-title"),
                location: Map.get(dog, "data-location"),
                data_id: data_id,
                age_text: Map.get(dog, "data-agetext"),
                gender: Map.get(dog, "data-gender"),
                primary_breed: Map.get(dog, "data-primarybreed"),
                species: Map.get(dog, "data-species"),
                campus: Map.get(dog, "data-campus"),
                details_url: Map.get(dog, "data-detailsurl"),
                profile_image_url: Map.get(dog, "data-bg")
              }
              |> Houses.create_pet()
            {:ok, pet} = result
            pet

          pet ->
            # Logger.debug("existing dog #{inspect pet}")
            Logger.info("existing dog #{pet.name}")
            Houses.ensure_available_dog(pet)
            pet
        end
      end)

    pets
    |> Enum.map(& &1.id)
    |> Houses.update_removed_dogs()
  end

  defp dogs_url(), do: @dogs_url

  defp get_dogs() do
    # HTTPoison.start()
    case get_body(dogs_url()) do
      nil ->
        nil
      body ->
        # article.animal-card:nth-child(25)
        # {
        #    "article",
        #    [
        #       {"class", "animal-card card c-lg-1-4 c-md-1-3 c-sm-1-2 "},
        #       {"data-id", "32544626"},
        #       {"data-querytype", "adoption-details"},
        #       {"data-name", "Gunner"},
        #       {"data-agetext", "10 years old"},
        #       {"data-gender", "Male"},
        #       {"data-primarybreed", "Retriever, Labrador"},
        #       {"data-species", "Dog"},
        #       {"data-description", ""},
        #       {"data-detailsurl", "https://hawaiianhumane.org/adoption-details/?animalID=32544626"},
        #       {"data-title", "'Gunner', a 10 years old Male Retriever, Labrador Dog"},
        #       {"data-campus", "moiliili"},
        #       {"data-location", "Couch Crasher Foster Home"}
        #    ],
        #    [
        #       {
        #          "div",
        #          [
        #             {"class", "card-img-top ratio-5-5 lazy"},
        #             {"style", "no-repeat center center; background-size: cover;"},
        #             {"data-bg", "url('https://g.petango.com/photos/3080/a7617072-19b7-401c-b923-7a211a2b4970.jpg')"}
        #          ],
        #          []
        #       },
        #       {
        #          "div",
        #          [
        #             {"class", "card-body"}
        #          ],
        #          [
        #             {"h4", [{"class", "animal-header"}], ["Gunner"]},
        #             {
        #                "ul",
        #                [{"class", "animal-details gray"}],
        #                [
        #                   {
        #                      "li",
        #                      [{"class", "animal-species-breed small text-truncate"}],
        #                      [
        #                         {
        #                            "span",
        #                            [{"class", "animal-species"}],
        #                            ["Dog"]
        #                         },
        #                         "\n              •\n              ",
        #                         {"span", [{"class", "animal-primary-breed"}], ["Retriever, Labrador"]},
        #                         {:comment, " Handling for secondary breeds being potentially empty "},
        #                         {"span", [{"class", "animal-secondary-breed"}], ["/\n                            Mix              "]}
        #                      ]
        #                   },
        #                   {"li", [{"class", "animal-gender small"}], ["\n                        Male            "]},
        #                   {
        #                      "li",
        #                      [{"class", "animal-age small"}, {"value", "129"}],
        #                      [
        #                         {:comment," Api returns age in months, handle conversion/presentation "},
        #                         "\n                        10 years old            "
        #                      ]
        #                   }
        #                ]
        #             }
        #          ]
        #       },
        #       {
        #          "div",
        #          [{"class", "animal-location card-footer"}],
        #          [{"span", [{"class", "small text-truncate"}], ["Location: Couch Crasher Foster Home"]}]
        #       }
        #    ]
        # }
        {:ok, document} = Floki.parse_document(body)
        result =
          document
          |> Floki.find("article.animal-card")
          |> Enum.map(fn {"article", data, html} ->
            %{}
            |> parse_data(data)
            |> parse_html(html)
          end)
        # IO.inspect(result, label: "result")
        result
    end
  end

  defp parse_data(info, data) do
    Enum.reduce(data, info, fn {id, val}, acc ->
      Map.put(acc, id, val)
    end)
  end

  defp parse_html(info, html) do
    html
    |> Floki.attribute("div.card-img-top", "data-bg")
    |> Enum.reduce(info, fn css_url, acc ->
      [_, url] = Regex.run(~r/url\('(.*)'\)/, css_url)
      Map.put(acc, "data-bg", url)
    end)
  end

  defp get_body(url) do
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, headers: headers, body: body}} ->
        if Utils.gzipped?(headers) do
          :zlib.gunzip(body)
        else
          body
        end
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        Logger.warning("Not found :(")
        nil
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.warning(reason)
        nil
    end
  end
end
