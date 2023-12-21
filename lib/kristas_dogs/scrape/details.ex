defmodule KristasDogs.Scrape.Details do
  require Logger

  alias KristasDogs.Repo

  alias KristasDogs.Houses.Pet
  alias KristasDogs.PetDetails
  alias KristasDogs.PetDetails.PetImage
  alias KristasDogs.Scrape.Utils

  @detail_url "https://hawaiianhumane.org/adoption-details/"

  def detail_url(animal_id), do: "#{@detail_url}?animalID=#{animal_id}"

  def record_details(%Pet{} = pet) do
    info =
      detail_url(pet.data_id)
      |> get_details()

    if is_nil(info) do
      PetDetails.update_pet_details_checked(pet)
    else
      process_details(info, pet)
    end
  end

  def process_details(info, %Pet{} = pet) do
    # update pet
    {:ok, pet} = PetDetails.update_pet_details(pet, info)

    # add images
    pet = pet |> Repo.preload([:pet_images])
    images = Map.get(info, :image_urls, [])
    pet_images =
      for url <- images do
        exists? =
          Enum.any?(pet.pet_images, fn %PetImage{} = pet_image ->
            pet_image.url == url
          end)
        unless exists? do
          {:ok, pet_image} =
            %{url: url, pet_id: pet.id}
            |> PetDetails.create_pet_image()
          pet_image
        else
          nil
        end
      end
      |> Enum.reject(&is_nil(&1))
    {pet, pet_images}
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

  # article = Floki.find(doc, "article.article-details-page")
  # article =
  # [
  #   {"article", [{"class", "container grid m-x-auto m-t-3 animal-details-page"}],
  #    [
  #      {:comment, "Visible on both modal and each animal's individual pages"},
  #      {"div", [{"class", "modal-col-left c-sm-1-2"}],
  #       [
  #         {"div", [{"id", "img-viewer"}, {"class", "ratio-1-1"}],
  #          [
  #            {"div", [{"class", "content-ratio"}],
  #             [
  #               {:comment, " Handle images/videos "},
  #               {"div",
  #                [
  #                  {"id", "animal-img-1"},
  #                  {"class", "img-wrapper active"},
  #                  {"data-img", "1"}
  #                ],
  #                [
  #                  {"img",
  #                   [
  #                     {"class", "lazy"},
  #                     {"src",
  #                      "data:image/svg+xml,%3Csvg%20xmlns='http://www.w3.org/2000/svg'%20viewBox='0%200%201%201'%3E%3C/svg%3E"},
  #                     {"data-src",
  #                      "https://g.petango.com/photos/3080/cd39007c-e05c-4230-a400-abbc0f4d6eb2.jpg"}
  #                   ], []}
  #                ]},
  #               {"div",
  #                [
  #                  {"id", "animal-img-2"},
  #                  {"class", "img-wrapper"},
  #                  {"data-img", "2"}
  #                ],
  #                [
  #                  {"img",
  #                   [
  #                     {"class", "lazy"},
  #                     {"src",
  #                      "data:image/svg+xml,%3Csvg%20xmlns='http://www.w3.org/2000/svg'%20viewBox='0%200%201%201'%3E%3C/svg%3E"},
  #                     {"data-src",
  #                      "https://g.petango.com/photos/3080/e3117899-24b0-42e8-8c5e-5082074c59f3.jpg"}
  #                   ], []}
  #                ]},
  #               {"div",
  #                [
  #                  {"id", "animal-img-3"},
  #                  {"class", "img-wrapper"},
  #                  {"data-img", "3"}
  #                ],
  #                [
  #                  {"img",
  #                   [
  #                     {"class", "lazy"},
  #                     {"src",
  #                      "data:image/svg+xml,%3Csvg%20xmlns='http://www.w3.org/2000/svg'%20viewBox='0%200%201%201'%3E%3C/svg%3E"},
  #                     {"data-src",
  #                      "https://g.petango.com/photos/3080/59725cc9-184a-4c3c-8517-3a5ec5f18175.jpg"}
  #                   ], []}
  #                ]}
  #             ]}
  #          ]},
  #         {"div", [{"id", "img-selector"}, {"class", "ratio-4-1"}],
  #          [
  #            {"div", [{"class", "content-ratio d-flex m-t-0-5"}],
  #             [
  #               {:comment, " Handle images/videos "},
  #               {"span",
  #                [
  #                  {"id", "animal-thumb-1"},
  #                  {"class", "img-thumb m-r-0-5 active lazy"},
  #                  {"style", "no-repeat center center; background-size: cover;"},
  #                  {"data-bg",
  #                   "url('https://g.petango.com/photos/3080/cd39007c-e05c-4230-a400-abbc0f4d6eb2.jpg')"},
  #                  {"data-img", "1"}
  #                ], []},
  #               {"span",
  #                [
  #                  {"id", "animal-thumb-2"},
  #                  {"class", "img-thumb m-r-0-5 lazy"},
  #                  {"style", "no-repeat center center; background-size: cover;"},
  #                  {"data-bg",
  #                   "url('https://g.petango.com/photos/3080/e3117899-24b0-42e8-8c5e-5082074c59f3.jpg')"},
  #                  {"data-img", "2"}
  #                ], []},
  #               {"span",
  #                [
  #                  {"id", "animal-thumb-3"},
  #                  {"class", "img-thumb m-r-0-5 lazy"},
  #                  {"style", "no-repeat center center; background-size: cover;"},
  #                  {"data-bg",
  #                   "url('https://g.petango.com/photos/3080/59725cc9-184a-4c3c-8517-3a5ec5f18175.jpg')"},
  #                  {"data-img", "3"}
  #                ], []}
  #             ]}
  #          ]},
  #         {"div", [{"class", "animal-description grid no-gutter"}],
  #          [
  #            {"span", [{"class", "description-value value c-1-1"}],
  #             [
  #               {"br", [], []},
  #               "This is Sammi! Sammi was brought to the Hawaiian Humane society as a stray found in Waianae. This handsome boy is very sweet and has great manners. He would make a great first pet for any family looking for a new addition. He can be shy when meeting new people, but will warm up immediately if you're patient and gentle with him. If you're interested in meeting this sweet boy, he is located at our Mo'ili'ili campus. Ask an adoptions representative about Sammi today!"
  #             ]}
  #          ]}
  #       ]},
  #      {:comment, " Adoption animal details "},
  #      {"div", [{"class", "modal-col-right c-sm-1-2"}],
  #       [
  #         {"h1", [{"class", "animal-header h2 m-y-0"}], ["Sammi"]},
  #         {"ul", [],
  #          [
  #            {"li", [{"class", "animal-species-breed m-b-3"}],
  #             [
  #               {"span", [], ["Dog"]},
  #               "\n      •\n      ",
  #               {"span", [{"class", "animal-primary-breed"}],
  #                ["Terrier, American Pit Bull"]},
  #               {:comment,
  #                " Handle adding a '/' for secondary breeds if present "},
  #               {"span", [{"class", "animal-secondary-breed"}], ["/ Mix"]}
  #             ]},
  #            {"li", [{"class", "animal-id grid no-gutter"}],
  #             [
  #               {"span", [{"class", "animal-id c-1-2 strong"}], ["ID:"]},
  #               {"span", [{"class", "id-value value c-1-2"}], ["54614871"]}
  #             ]},
  #            {"li", [{"class", "animal-size grid no-gutter"}],
  #             [
  #               {"span", [{"class", "animal-size c-1-2 strong"}], ["Size:"]},
  #               {"span", [{"class", "size-value value c-1-2"}], ["Large"]}
  #             ]},
  #            {"li", [{"class", "animal-gender grid no-gutter"}],
  #             [
  #               {"span", [{"class", "animal-gender c-1-2 strong"}], ["Gender:"]},
  #               {"span", [{"class", "gender-value value c-1-2"}], ["Male"]}
  #             ]},
  #            {"li", [{"class", "animal-age grid no-gutter"}],
  #             [
  #               {"span", [{"class", "animal-age c-1-2 strong"}], ["Age:"]},
  #               {"span", [{"class", "age-value value c-1-2"}], ["2 years old"]}
  #             ]},
  #            {"li", [{"class", "animal-weight grid no-gutter"}],
  #             [
  #               {"span", [{"class", "animal-weight c-1-2 strong"}], ["Weight:"]},
  #               {"span", [{"class", "weight-value value c-1-2"}], ["58 lbs"]}
  #             ]},
  #            {"li", [{"class", "animal-altered grid no-gutter"}],
  #             [
  #               {"span", [{"class", "animal-altered c-1-2 strong"}], ["Altered:"]},
  #               {"span", [{"class", "altered-value value c-1-2"}], ["Yes"]}
  #             ]},
  #            {"li", [{"class", "animal-location grid no-gutter m-b-2"}],
  #             [
  #               {"span", [{"class", "animal-location c-1-2 strong"}],
  #                ["Location:"]},
  #               {"span", [{"class", "location-value value c-1-2"}],
  #                ["Dog House Blue", {"br", [], []}, "Mō’ili’ili Campus"]}
  #             ]}
  #          ]},
  #         {"a", [{"href", "https://hawaiianhumane.org/adoptions/"}],
  #          ["Adoption Pricing & Details"]},
  #         {:comment, " Share animal profile "},
  #         {"hr", [{"class", "m-y-3"}], []},
  #         {"div", [{"class", "share-container"}],
  #          [
  #            {"span", [{"class", "strong"}],
  #             ["Share\n      Sammi's      profile:"]},
  #            {"div", [{"class", "a2a_kit a2a_kit_size_32 a2a_default_style"}],
  #             [
  #               {"a",
  #                [
  #                  {"class", "a2a_button_facebook"},
  #                  {"style", "padding: 8px 8px 2px 0px;"}
  #                ], []},
  #               {"a",
  #                [
  #                  {"class", "a2a_button_twitter"},
  #                  {"style", "padding: 8px 8px 2px 0px;"}
  #                ], []},
  #               {"a",
  #                [
  #                  {"class", "a2a_button_email"},
  #                  {"style", "padding: 8px 8px 2px 0px;"}
  #                ], []},
  #               {"a",
  #                [
  #                  {"class", "a2a_dd"},
  #                  {"href", "https://www.addtoany.com/share"},
  #                  {"style", "padding: 8px 8px 2px 0px;"}
  #                ], []}
  #             ]}
  #          ]},
  #         {"a",
  #          [
  #            {"class", "donate-support btn btn-outline"},
  #            {"href",
  #             "https://give.hawaiianhumane.org/give/481351/#!/donation/checkout"}
  #          ], ["Support My\n    Care"]}
  #       ]},
  #      {:comment, " /Adoption animal details "},
  #      {"script", [{"type", "text/javascript"}],
  #       ["\n/**\n * 'AddToAny' plugin requirements for sharing, email template, etc.\n * @data-a2a-url (HTML)/@${link} (Email Template) {String} - The URL AddToAny will share.\n * @data-a2a-title (HTML)/@${title} (Email Template) {String} - The Title/Email Subject AddToAny will share.\n */\n\nvar animalModal = document.querySelector('div#animalModal') ? document.querySelector('div#animalModal') : '';\nvar a2aKit = animalModal ? animalModal.querySelector('div.a2a_kit') : document.querySelector('div.a2a_kit');\n\na2aKit.setAttribute(\"data-a2a-url\", \"https://hawaiianhumane.org/adoption-details/?animalID=54614871\");\na2aKit.setAttribute(\"data-a2a-title\", \"'Sammi', a 2 years old Male Terrier, American Pit Bull Dog\");\n\na2a_config.templates.email = {\n  subject: 'Check out this pet: ${title}',\n  body: 'This is Sammi! Sammi was brought to the Hawaiian Humane society as a stray found in Waianae. This handsome boy is very sweet and has great manners. He would make a great first pet for any family looking for a new addition. He can be shy when meeting new people, but will warm up immediately if you&#39;re patient and gentle with him. If you&#39;re interested in meeting this sweet boy, he is located at our Mo&#39;ili&#39;ili campus. Ask an adoptions representative about Sammi today!\\n\\nTo learn more, check out the URL below!\\n\\n${link}'\n};\n\n// feature image viewer\nvar imgViewer = document.querySelector('div#img-viewer');\nvar viewerImages = imgViewer.querySelectorAll('div.img-wrapper');\n\n// add 'click' event listeners to each img-selector image thumbnail that will toggle img-viewer feature image active state\nvar imgThumbnails = document.querySelectorAll('span.img-thumb');\n\n// handle 'active' class toggle\nimgThumbnails.forEach(function(img) {\n  img.addEventListener('click', function(e) {\n    // current 'active' feature image & thumbnail\n    var currentActiveThumbnail = document.querySelector('span.img-thumb.active');\n    var currentActiveFeatureImage = imgViewer.querySelector('div.img-wrapper.active');\n\n    // Regex to search for 'active' pattern\n    var activeStrPattern = new RegExp(\"active\");\n    var active = activeStrPattern.test(img.className);\n\n    if (active) {\n      return;\n    } else {\n      // reset 'active' state of feature image & thumbnail\n      currentActiveThumbnail.classList.remove('active');\n      currentActiveFeatureImage.classList.remove('active');\n\n      // set feature image to selected/clicked thumbnail image\n      viewerImages.forEach(function(viewerImage) {\n        if (viewerImage.dataset.img === img.dataset.img) {\n          img.classList.add('active');\n          viewerImage.classList.add('active');\n        }\n      });\n    }\n  });\n});\n"]},
  #      {:comment, " More animals section "},
  #      {:comment, " Grab species label based on ID "},
  #      {"div", [{"class", "grid m-t-3"}],
  #       [
  #         {"div", [{"class", "c-1-1"}],
  #          [
  #            {"h5", [{"class", "alt m-b-1"}],
  #             ["More Dogs Available for Adoption"]},
  #            {"hr", [], []}
  #          ]},
  #         {:comment,
  #          " Iterate through each animal node in XML to generate listing "},
  #         {"h4", [{"class", "alt c-b-1"}], ["No Dogs currently available."]},
  #         {:comment,
  #          " Display link to see all animals based on what type of search this is "},
  #         {"a",
  #          [
  #            {"href",
  #             "https://hawaiianhumane.org/adoptions/available-animals/?speciesID=1"},
  #            {"class", "c-1-1 text-center m-b-4"}
  #          ], ["SEE ALL DOG ADOPTIONS >"]}
  #       ]},
  #      {:comment,
  #       " Display \"content\" used to display sharing plugin associated with page/post content "},
  #      {:comment, " Edit link "}
  #    ]}
  # ]
  def get_details(url) do
    case get_body(url) do
      nil ->
        nil
      body ->
        {:ok, document} = Floki.parse_document(body)
        article =
          document
          |> Floki.find("article.animal-details-page")
        parse_article(article)
    end
  end

  def parse_article(article) do
    case article do
      [] ->
        nil
      _ ->
        %{}
        |> parse_html(article)
    end
  end

  defp parse_html(info, article_html) do
    info
    |> Map.put(:description, get_description(article_html))
    |> Map.put(:size, get_size(article_html))
    |> Map.put(:weight, get_weight(article_html))
    |> Map.put(:altered, get_altered(article_html))
    |> Map.put(:image_urls, get_image_urls(article_html))
  end

  defp get_text(article_html, selector) do
    article_html
    |> Floki.find(selector)
    |> List.first()
    |> Floki.text()
    |> trim()
  end

  def get_description(article_html) do
    article_html
    |> get_text(".description-value")
    |> replace_prefix("\n", "")
  end

  def get_size(article_html) do
    article_html
    |> get_text(".animal-size .size-value")
  end

  def get_weight(article_html) do
    article_html
    |> get_text(".animal-weight .weight-value")
  end

  def get_altered(article_html) do
    article_html
    |> get_text(".animal-altered .altered-value")
    |> String.downcase()
    |> case do
      "yes" -> true
      "no" -> false
      _ -> nil
    end
  end

  # [
  #   {"span",
  #    [
  #      {"id", "animal-thumb-1"},
  #      {"class", "img-thumb m-r-0-5 active lazy"},
  #      {"style", "no-repeat center center; background-size: cover;"},
  #      {"data-bg",
  #       "url('https://g.petango.com/photos/3080/cd39007c-e05c-4230-a400-abbc0f4d6eb2.jpg')"},
  #      {"data-img", "1"}
  #    ], []},
  #   {"span",
  #    [
  #      {"id", "animal-thumb-2"},
  #      {"class", "img-thumb m-r-0-5 lazy"},
  #      {"style", "no-repeat center center; background-size: cover;"},
  #      {"data-bg",
  #       "url('https://g.petango.com/photos/3080/e3117899-24b0-42e8-8c5e-5082074c59f3.jpg')"},
  #      {"data-img", "2"}
  #    ], []},
  #   {"span",
  #    [
  #      {"id", "animal-thumb-3"},
  #      {"class", "img-thumb m-r-0-5 lazy"},
  #      {"style", "no-repeat center center; background-size: cover;"},
  #      {"data-bg",
  #       "url('https://g.petango.com/photos/3080/59725cc9-184a-4c3c-8517-3a5ec5f18175.jpg')"},
  #      {"data-img", "3"}
  #    ], []}
  # ]
  def get_image_urls(article_html) do
    article_html
    |> Floki.find("#img-selector .img-thumb")
    |> Floki.attribute("data-bg")
    |> Enum.map(fn attr ->
      Regex.named_captures(~r/url\('(?<url>[^\s]*)'\)/, attr)
      |> Map.get("url", nil)
    end)
    |> Enum.reject(&is_nil(&1))
  end

  def trim(nil), do: nil
  def trim(""), do: nil
  def trim(s) do
    s
    |> String.trim()
    |> case do
      "" -> nil
      other -> other
    end
  end

  def replace_prefix(nil, _find, _replace), do: nil
  def replace_prefix(s, find, replace), do: String.replace_prefix(s, find, replace)
end
