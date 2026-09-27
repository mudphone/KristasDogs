defmodule KristasDogsWeb.StatsLive.IndexTest do
  use KristasDogsWeb.ConnCase

  import Phoenix.LiveViewTest
  import KristasDogs.DogStatsFixtures

  test "renders all five adoption-time charts with a per-dog hover tooltip", %{conn: conn} do
    dog =
      adopted_dog_fixture(%{
        name: "Wednesday",
        normal_primary_breed: "Terrier",
        size: "Medium",
        gender: "Male",
        normal_age_months: 24,
        normal_weight_lbs: 40.0,
        inserted_at: ~U[2024-01-01 00:00:00Z],
        removed_from_website_at: ~U[2024-01-11 00:00:00Z]
      })

    {:ok, _view, html} = live(conn, ~p"/stats")

    assert html =~ "Adoption Time Stats"
    assert html =~ "By Breed"
    assert html =~ "By Size"
    assert html =~ "By Gender"
    assert html =~ "By Age"
    assert html =~ "By Weight"
    assert html =~ "Terrier"
    assert html =~ "<title>Wednesday (ID: #{dog.id})</title>"
    assert html =~ "dot-highlight"
    assert html =~ "dot-group"
  end

  test "renders without error when there are no adopted dogs at all", %{conn: conn} do
    assert {:ok, _view, html} = live(conn, ~p"/stats")
    assert html =~ "Adoption Time Stats"
  end
end
