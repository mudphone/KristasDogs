defmodule KristasDogs.Scrape.Dogs do
  require Logger

  alias KristasDogs.Houses
  alias KristasDogs.Scrape.Utils

  @dogs_url "https://www.hawaiianhumane.org/adoptions/available-animals/?speciesID=1"

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
                profile_image_url: Map.get(dog, "image-url")
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
  # %{
  #   "class" => "animal-card card c-lg-1-4 c-md-1-3 c-sm-1-2 ",
  #   "data-agetext" => "1 year old",
  #   "data-campus" => "offsite",
  #   "data-description" => "",
  #   "data-detailsurl" => "https://www.hawaiianhumane.org/adoption-details/?animalID=55279662",
  #   "data-gender" => "Female",
  #   "data-id" => "55279662",
  #   "data-location" => "M- Field Trip",
  #   "data-name" => "Wednesday",
  #   "data-primarybreed" => "Terrier, American Pit Bull",
  #   "data-querytype" => "adoption-details",
  #   "data-species" => "Dog",
  #   "data-title" => "'Wednesday', a 1 year old Female Terrier, American Pit Bull Dog"
  # }

  def dogs_url(), do: @dogs_url

  defp get_dogs() do
    # HTTPoison.start()
    case get_body(dogs_url()) do
      nil ->
        nil
      body ->
        # Run this:
        #   {:ok, doc} = Floki.parse_document(body)
        #    doc |> Floki.find("article.animal-card")
        # Returns this:
        # {"article",
        #   [
        #     {"class", "animal-card card c-lg-1-4 c-md-1-3 c-sm-1-2 "},
        #     {"data-id", "58364904"},
        #     {"data-querytype", "adoption-details"},
        #     {"data-name", "Hinano"},
        #     {"data-agetext", "4 months old"},
        #     {"data-gender", "Female"},
        #     {"data-primarybreed", "Chinese Shar-Pei"},
        #     {"data-species", "Dog"},
        #     {"data-description", ""},
        #     {"data-detailsurl",
        #       "https://www.hawaiianhumane.org/adoption-details/?animalID=58364904"},
        #     {"data-title", "'Hinano', a 4 months old Female Chinese Shar-Pei Dog"},
        #     {"data-campus", "moiliili"},
        #     {"data-location", "M- Dog House Green"}
        #   ],
        #   [
        #     {"div",
        #       [
        #         {"class", "card-img-top ratio-5-5"},
        #         {"style",
        #         "background: url('https://g.petango.com/photos/3080/18415444-d603-4355-be7c-ba3557bb32a4.jpg') no-repeat center center; background-size: cover;"}
        #       ], []},
        #     {"div", [{"class", "card-body"}],
        #       [
        #         {"h4", [{"class", "animal-header"}], ["Hinano"]},
        #         {"ul", [{"class", "animal-details gray"}],
        #         [
        #           {"li", [{"class", "animal-species-breed small text-truncate"}],
        #             [
        #               {"span", [{"class", "animal-species"}], ["Dog"]},
        #               "\n              •\n              ",
        #               {"span", [{"class", "animal-primary-breed"}], ["Chinese Shar-Pei"]},
        #               {:comment,
        #               " Handling for secondary breeds being potentially empty "},
        #               {"span", [{"class", "animal-secondary-breed"}],
        #               ["/\n                            Mix              "]}
        #             ]},
        #           {"li", [{"class", "animal-gender small"}],
        #             ["\n                        Female            "]},
        #           {"li", [{"class", "animal-age small"}, {"value", "4"}],
        #             [
        #               {:comment,
        #               " Api returns age in months, handle conversion/presentation "},
        #               "\n                        4 months old            "
        #             ]}
        #         ]}
        #       ]},
        #     {"div", [{"class", "animal-location card-footer"}],
        #       [
        #         {"span", [{"class", "small text-truncate"}],
        #         ["Location: Dog House Green", {"br", [], []}, "Mō’ili’ili Campus"]}
        #       ]}
        #   ]}
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

  # [
  #   {"class", "animal-card card c-lg-1-4 c-md-1-3 c-sm-1-2 "},
  #   {"data-id", "58364904"},
  #   {"data-querytype", "adoption-details"},
  #   {"data-name", "Hinano"},
  #   {"data-agetext", "4 months old"},
  #   {"data-gender", "Female"},
  #   {"data-primarybreed", "Chinese Shar-Pei"},
  #   {"data-species", "Dog"},
  #   {"data-description", ""},
  #   {"data-detailsurl",
  #   "https://www.hawaiianhumane.org/adoption-details/?animalID=58364904"},
  #   {"data-title", "'Hinano', a 4 months old Female Chinese Shar-Pei Dog"},
  #   {"data-campus", "moiliili"},
  #   {"data-location", "M- Dog House Green"}
  # ]
  defp parse_data(info, data) do
    Enum.reduce(data, info, fn {id, val}, acc ->
      Map.put(acc, id, val)
    end)
  end

  # [
  #   {"div",
  #   [
  #     {"class", "card-img-top ratio-5-5"},
  #     {"style",
  #       "background: url('https://g.petango.com/photos/3080/18415444-d603-4355-be7c-ba3557bb32a4.jpg') no-repeat center center; background-size: cover;"}
  #   ], []},
  #   {"div", [{"class", "card-body"}],
  #   [
  #     {"h4", [{"class", "animal-header"}], ["Hinano"]},
  #     {"ul", [{"class", "animal-details gray"}],
  #       [
  #         {"li", [{"class", "animal-species-breed small text-truncate"}],
  #         [
  #           {"span", [{"class", "animal-species"}], ["Dog"]},
  #           "\n              •\n              ",
  #           {"span", [{"class", "animal-primary-breed"}], ["Chinese Shar-Pei"]},
  #           {:comment, " Handling for secondary breeds being potentially empty "},
  #           {"span", [{"class", "animal-secondary-breed"}],
  #             ["/\n                            Mix              "]}
  #         ]},
  #         {"li", [{"class", "animal-gender small"}],
  #         ["\n                        Female            "]},
  #         {"li", [{"class", "animal-age small"}, {"value", "4"}],
  #         [
  #           {:comment,
  #             " Api returns age in months, handle conversion/presentation "},
  #           "\n                        4 months old            "
  #         ]}
  #       ]}
  #   ]},
  #   {"div", [{"class", "animal-location card-footer"}],
  #   [
  #     {"span", [{"class", "small text-truncate"}],
  #       ["Location: Dog House Green", {"br", [], []}, "Mō’ili’ili Campus"]}
  #   ]}
  # ]
  defp parse_html(info, html) do
    html
    |> Floki.attribute("div.card-img-top", "style")
    |> Enum.reduce(info, fn css_url, acc ->
      [_, url] = Regex.run(~r/url\('(.*)'\)/, css_url)
      Map.put(acc, "image-url", url)
    end)
  end

  def get_body(url) do
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
