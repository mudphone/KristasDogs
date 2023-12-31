defmodule KristasDogsWeb.DogsLive.Pager do
  use Phoenix.LiveComponent
  use Phoenix.VerifiedRoutes,
    endpoint: KristasDogsWeb.Endpoint,
    router: KristasDogsWeb.Router

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end
end
