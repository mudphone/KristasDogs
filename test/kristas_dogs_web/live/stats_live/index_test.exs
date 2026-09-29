defmodule KristasDogsWeb.StatsLive.IndexTest do
  use KristasDogsWeb.ConnCase

  import Phoenix.LiveViewTest
  import KristasDogs.DogStatsFixtures

  test "renders all five time-listed charts with a canvas dot overlay for each", %{conn: conn} do
    listed_dog_fixture(%{
      name: "Wednesday",
      normal_primary_breed: "Terrier",
      size: "Medium",
      gender: "Male",
      normal_age_months: 24,
      normal_weight_lbs: 40.0,
      inserted_at: ~U[2025-07-01 00:00:00Z],
      removed_from_website_at: ~U[2025-07-11 00:00:00Z]
    })

    {:ok, _view, html} = live(conn, ~p"/stats")

    assert html =~ "Time Listed Stats"
    assert html =~ "By Breed"
    assert html =~ "By Size"
    assert html =~ "By Gender"
    assert html =~ "By Age"
    assert html =~ "By Weight"
    assert html =~ "Terrier"

    assert html =~ ~s(id="chart-dots-breed")
    assert html =~ ~s(id="chart-dots-size")
    assert html =~ ~s(id="chart-dots-gender")
    assert html =~ ~s(id="chart-dots-age")
    assert html =~ ~s(id="chart-dots-weight")
    assert html =~ ~s(phx-hook="ChartDots")
    assert html =~ ~s(data-dots-url="/api/stats/dots/breed")
    assert html =~ "Click a dot for details"
  end

  test "renders without error when there are no listed dogs at all", %{conn: conn} do
    assert {:ok, _view, html} = live(conn, ~p"/stats")
    assert html =~ "Time Listed Stats"
  end
end
