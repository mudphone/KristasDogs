defmodule KristasDogsWeb.DogsLive.Pager do
  use Phoenix.LiveComponent

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end
end
