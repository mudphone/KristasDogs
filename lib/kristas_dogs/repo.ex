defmodule KristasDogs.Repo do
  use Ecto.Repo,
    otp_app: :kristas_dogs,
    adapter: Ecto.Adapters.SQLite3
end
