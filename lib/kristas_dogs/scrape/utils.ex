defmodule KristasDogs.Scrape.Utils do

  def gzipped?(headers) do
    Enum.any?(headers, fn {name, value} ->
      # Headers are case-insensitive so we compare their lower case form.
      String.downcase(name) == "content-encoding" and
        String.downcase(value) == "gzip"
    end)
  end
end
