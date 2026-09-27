defmodule KristasDogs.Houses.PetNormalization do
  @moduledoc """
  Pure parsing rules that turn the raw scraped pet fields (primary_breed,
  age_text, weight) into normalized values suitable for grouping and
  charting. No database access.
  """

  @doc """
  Normalizes a primary_breed value into a natural single-breed name.

  primary_breed is stored as "Group, Variety[, Sub-variety]" for a
  single breed (never multiple breeds). For example, "Terrier, Jack Russell"
  is Jack Russell Terrier. This reverses the comma-separated segments and
  joins them with spaces. Any value starting with "Mixed Breed" collapses
  to exactly "Mixed Breed", dropping its size-derived suffix.
  """
  def normalize_primary_breed(nil), do: nil

  def normalize_primary_breed(breed) do
    breed = String.trim(breed)

    if String.starts_with?(breed, "Mixed Breed") do
      "Mixed Breed"
    else
      breed
      |> String.split(", ")
      |> Enum.reverse()
      |> Enum.join(" ")
    end
  end

  @doc """
  Parses age_text (e.g. "2 years old", "6 months old") into a whole
  number of months. Returns nil for blank/missing text, unparseable
  text, or an implausible age (420 months / 35 years or more) -- real
  dogs never get anywhere near that old, so a value like "125 years
  old" or "126 years old" is bad scraped data, not a real age.
  """
  def normalize_age_months(nil), do: nil
  def normalize_age_months(""), do: nil

  def normalize_age_months(age_text) do
    case Regex.run(~r/^(\d+)\s+(year|years|month|months)\s+old$/, String.trim(age_text)) do
      [_, num_str, unit] ->
        num = String.to_integer(num_str)
        months = if String.starts_with?(unit, "year"), do: num * 12, else: num
        if months >= 420, do: nil, else: months

      nil ->
        nil
    end
  end

  @doc """
  Parses weight (e.g. "23 lbs", "40.20 pounds") into a float number of
  pounds. Returns nil for the literal "N/A" sentinel, blank/missing
  weight, or unparseable text.
  """
  def normalize_weight_lbs(nil), do: nil
  def normalize_weight_lbs(""), do: nil
  def normalize_weight_lbs("N/A"), do: nil

  def normalize_weight_lbs(weight) do
    case Regex.run(~r/^(\d+(?:\.\d+)?)\s+(?:lbs|pounds)$/, String.trim(weight)) do
      [_, num_str] -> String.to_float(ensure_decimal(num_str))
      nil -> nil
    end
  end

  defp ensure_decimal(num_str) do
    if String.contains?(num_str, "."), do: num_str, else: num_str <> ".0"
  end
end
