defmodule KristasDogsWeb.DotsControllerTest do
  use KristasDogsWeb.ConnCase

  import KristasDogs.DogStatsFixtures

  describe "GET /api/stats/dots/breed" do
    test "returns one entry per dog with id, x, y, name, category, and days", %{conn: conn} do
      adopted_dog_fixture(%{name: "Wednesday", normal_primary_breed: "Terrier"})

      conn = get(conn, ~p"/api/stats/dots/breed")

      assert [dot] = json_response(conn, 200)
      assert dot["name"] == "Wednesday"
      assert dot["category"] == "Terrier"
      assert dot["days"] == 10
      assert is_number(dot["x"])
      assert is_number(dot["y"])
    end

    test "sets Cache-Control: no-cache and a content-hash ETag", %{conn: conn} do
      adopted_dog_fixture()

      conn = get(conn, ~p"/api/stats/dots/breed")

      assert get_resp_header(conn, "cache-control") == ["no-cache"]
      assert [etag] = get_resp_header(conn, "etag")
      assert etag =~ ~r/^"[0-9a-f]{64}"$/
    end

    test "returns 304 with no body when If-None-Match matches the current ETag", %{conn: conn} do
      adopted_dog_fixture()

      first = get(conn, ~p"/api/stats/dots/breed")
      [etag] = get_resp_header(first, "etag")

      second =
        build_conn()
        |> put_req_header("if-none-match", etag)
        |> get(~p"/api/stats/dots/breed")

      assert second.status == 304
      assert second.resp_body == ""
    end

    test "returns 200 with a fresh body when If-None-Match doesn't match", %{conn: conn} do
      adopted_dog_fixture()

      conn =
        conn
        |> put_req_header("if-none-match", ~s("stale-etag"))
        |> get(~p"/api/stats/dots/breed")

      assert [_dot] = json_response(conn, 200)
    end
  end

  describe "GET /api/stats/dots/age" do
    test "formats the age value the same way the old hover tooltip did", %{conn: conn} do
      adopted_dog_fixture(%{normal_age_months: 24})

      conn = get(conn, ~p"/api/stats/dots/age")

      assert [dot] = json_response(conn, 200)
      assert dot["category"] == "2.0 years"
    end
  end

  describe "GET /api/stats/dots/weight" do
    test "passes the weight value through as a plain number string", %{conn: conn} do
      adopted_dog_fixture(%{normal_weight_lbs: 40.0})

      conn = get(conn, ~p"/api/stats/dots/weight")

      assert [dot] = json_response(conn, 200)
      assert dot["category"] == "40.0"
    end
  end

  describe "GET /api/stats/dots/size" do
    test "returns dots grouped by size category", %{conn: conn} do
      adopted_dog_fixture(%{size: "Large"})

      conn = get(conn, ~p"/api/stats/dots/size")

      assert [%{"category" => "Large"}] = json_response(conn, 200)
    end
  end

  describe "GET /api/stats/dots/gender" do
    test "returns dots grouped by gender category", %{conn: conn} do
      adopted_dog_fixture(%{gender: "Female"})

      conn = get(conn, ~p"/api/stats/dots/gender")

      assert [%{"category" => "Female"}] = json_response(conn, 200)
    end
  end
end
