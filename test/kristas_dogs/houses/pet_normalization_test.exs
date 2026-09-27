defmodule KristasDogs.Houses.PetNormalizationTest do
  use ExUnit.Case, async: true

  alias KristasDogs.Houses.PetNormalization

  describe "normalize_primary_breed/1" do
    test "passes through a value with no comma unchanged" do
      assert PetNormalization.normalize_primary_breed("Affenpinscher") == "Affenpinscher"
      assert PetNormalization.normalize_primary_breed("Terrier") == "Terrier"
    end

    test "reverses a single-comma Group, Variety value" do
      assert PetNormalization.normalize_primary_breed("Terrier, Jack Russell") == "Jack Russell Terrier"
      assert PetNormalization.normalize_primary_breed("Bulldog, French") == "French Bulldog"
      assert PetNormalization.normalize_primary_breed("Retriever, Labrador") == "Labrador Retriever"
    end

    test "reverses a two-comma Group, Variety, Sub-variety value" do
      assert PetNormalization.normalize_primary_breed("Terrier, Fox, Wire") == "Wire Fox Terrier"
      assert PetNormalization.normalize_primary_breed("Terrier, Fox, Smooth") == "Smooth Fox Terrier"
    end

    test "collapses every Mixed Breed variant to just Mixed Breed" do
      assert PetNormalization.normalize_primary_breed("Mixed Breed, Large (over 44 lbs fully grown)") == "Mixed Breed"
      assert PetNormalization.normalize_primary_breed("Mixed Breed, Medium (up to 44 lbs fully grown)") == "Mixed Breed"
      assert PetNormalization.normalize_primary_breed("Mixed Breed, Small (under 24 lbs fully grown)") == "Mixed Breed"
    end

    test "leaves a hyphenated value with no comma unchanged" do
      assert PetNormalization.normalize_primary_breed("Bully American - XL") == "Bully American - XL"
    end

    test "returns nil for nil" do
      assert PetNormalization.normalize_primary_breed(nil) == nil
    end
  end

  describe "normalize_age_months/1" do
    test "converts whole years to months" do
      assert PetNormalization.normalize_age_months("1 year old") == 12
      assert PetNormalization.normalize_age_months("2 years old") == 24
      assert PetNormalization.normalize_age_months("15 years old") == 180
    end

    test "keeps whole months as-is" do
      assert PetNormalization.normalize_age_months("1 month old") == 1
      assert PetNormalization.normalize_age_months("11 months old") == 11
    end

    test "returns nil for implausibly old ages (420 months / 35 years or more)" do
      assert PetNormalization.normalize_age_months("125 years old") == nil
      assert PetNormalization.normalize_age_months("126 years old") == nil
      assert PetNormalization.normalize_age_months("35 years old") == nil
    end

    test "keeps ages just under the implausibility threshold" do
      assert PetNormalization.normalize_age_months("34 years old") == 408
    end

    test "returns nil for blank, missing, or unparseable text" do
      assert PetNormalization.normalize_age_months(nil) == nil
      assert PetNormalization.normalize_age_months("") == nil
      assert PetNormalization.normalize_age_months("some age_text") == nil
    end
  end

  describe "normalize_weight_lbs/1" do
    test "parses the \"N lbs\" format" do
      assert PetNormalization.normalize_weight_lbs("23 lbs") == 23.0
      assert PetNormalization.normalize_weight_lbs("120 lbs") == 120.0
    end

    test "parses the \"N.NN pounds\" format" do
      assert PetNormalization.normalize_weight_lbs("40.20 pounds") == 40.20
      assert PetNormalization.normalize_weight_lbs("9.40 pounds") == 9.40
    end

    test "returns nil for N/A, blank, missing, or unparseable text" do
      assert PetNormalization.normalize_weight_lbs("N/A") == nil
      assert PetNormalization.normalize_weight_lbs("") == nil
      assert PetNormalization.normalize_weight_lbs(nil) == nil
      assert PetNormalization.normalize_weight_lbs("unknown") == nil
    end
  end
end
