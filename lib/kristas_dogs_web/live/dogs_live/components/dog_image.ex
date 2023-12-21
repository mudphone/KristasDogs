defmodule KristasDogsWeb.DogsLive.DogImage do
  use Phoenix.LiveComponent

  alias KristasDogs.Houses.Pet

  def update(%{dog: %Pet{} = dog} = assigns, socket) do
    detail_images = Enum.map(dog.pet_images, &(&1.url))
    all_images =
      [dog.profile_image_url]
      |> Enum.concat(detail_images)
      |> MapSet.new()
      |> MapSet.to_list()
    num_images = Enum.count(all_images)
    image_index = 0
    socket =
      socket
      |> assign(assigns)
      |> assign(
        all_images: Map.get(assigns, :all_images, all_images),
        image_index: Map.get(assigns, :image_index, 0),
        dog_image: Enum.at(all_images, image_index),
        num_images: num_images
      )
    {:ok, socket}
  end

  def handle_event("image-change", _params, %{assigns: assigns} = socket) do
    %{image_index: image_index,
      all_images: all_images,
      num_images: num_images} = assigns
    image_index = Integer.mod(image_index + 1, num_images)
    dog_image = Enum.at(all_images, image_index)
    socket =
      socket
      |> assign(
        dog_image: dog_image,
        image_index: image_index
      )
    {:noreply, socket}
  end
end
