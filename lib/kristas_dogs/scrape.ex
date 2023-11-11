defmodule KristasDogs.Scrape do
  require Logger

  def get_dogs() do
    # HTTPoison.start()
    url = "https://hawaiianhumane.org/adoptions/available-animals/?speciesID=1"
    case get_body(url) do
      nil ->
        nil
      body ->
        {:ok, document} = Floki.parse_document(body)
        # Logger.debug(body)
        document
        # |> Floki.find("article.animal-card > div:nth-child(2) > h4")
        #             article.animal-card:nth-child(25) > div:nth-child(2) > h4:nth-child(1)
        # |> Enum.map(fn {"h4", [{"class", "animal-header"}], [name]} ->

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
        |> Floki.find("article.animal-card")
        |> Enum.map(fn {"article", data, html} ->
          info =
            %{}
            |> parse_data(data)
            |> parse_html(html)
          # Logger.debug(data_lookup)
          IO.inspect(info, label: "info")
        end)
    end
  end

  def parse_data(info, data) do
    Enum.reduce(data, info, fn {id, val}, acc ->
      Map.put(acc, id, val)
    end)
  end

  def parse_html(info, html) do
    html
    |> Floki.attribute("div.card-img-top", "data-bg")
    |> Enum.map(fn css_url ->
      # IO.inspect(x, label: "card")
      [_, url] = Regex.run(~r/url\('(.*)'\)/, css_url)
      Map.put(info, "data-bg", url)
    end)
    # |> IO.inspect(label: "item"))
    # info
  end

  def get_body(url) do
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        # IO.puts body
        body
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        Logger.warning("Not found :(")
        nil
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.warning(reason)
        nil
    end
  end
end
