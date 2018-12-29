defmodule AwesomeWeb.PageControllerTest do
  use AwesomeWeb.ConnCase, async: false

  import Mock

  def get_data() do
    %{
      "Chapter1.Name" => %{
        "name" => "Chapter1.Name",
        "description" => "Chapter1.Description",
        "reference" => "chapter1",
        "projects" => %{
          "Chapter1.Project1.Name" => %{
            "description" => "Chapter1.Project1.Description",
            "link" => "https://Chapter1.Project1.Link",
            "name" => "Chapter1.Project1.Name",
            "seconds_off" => 2 * 24 * 60 * 60,
            "stars" => 1
          },
          "Chapter1.Project2.Name" => %{
            "description" => "Chapter1.Project2.Description",
            "link" => "https://Chapter1.Project2.Link",
            "name" => "Chapter1.Project2.Name",
            "seconds_off" => 4 * 24 * 60 * 60,
            "stars" => 3
          }
        }
      },
      "Chapter2.Name" => %{
        "name" => "Chapter2.Name",
        "description" => "Chapter2.Description",
        "reference" => "chapter2",
        "projects" => %{
          "Chapter2.Project1.Name" => %{
            "description" => "Chapter2.Project1.Description",
            "link" => "https://Chapter2.Project1.Link",
            "name" => "Chapter2.Project1.Name",
            "seconds_off" => 6 * 24 * 60 * 60,
            "stars" => 5
          },
          "Chapter2.Project2.Name" => %{
            "description" => "Chapter2.Project2.Description",
            "link" => "https://Chapter2.Project2.Link",
            "name" => "Chapter2.Project2.Name",
            "seconds_off" => 8 * 24 * 60 * 60,
            "stars" => 7
          }
        }
      }
    }
  end

  test "GET /" do
    with_mock Awesome.Fetcher.API, get_data: &get_data/0 do
      conn = get(build_conn(), "/")

      assert html_response(conn, 200) =~ "Awesome Elixir"
      assert html_response(conn, 200) =~ "Chapter1.Name"
      assert html_response(conn, 200) =~ "Chapter1.Description"
      assert html_response(conn, 200) =~ "Chapter1.Project1.Name"
      assert html_response(conn, 200) =~ "⭐<sub>1</sub> 📅<sub>2</sub>"
      assert html_response(conn, 200) =~ "Chapter1.Project1.Description"
      assert html_response(conn, 200) =~ "Chapter1.Project2.Name"
      assert html_response(conn, 200) =~ "⭐<sub>3</sub> 📅<sub>4</sub>"
      assert html_response(conn, 200) =~ "Chapter1.Project2.Description"

      assert html_response(conn, 200) =~ "Chapter2.Name"
      assert html_response(conn, 200) =~ "Chapter2.Description"
      assert html_response(conn, 200) =~ "Chapter2.Project1.Name"
      assert html_response(conn, 200) =~ "⭐<sub>5</sub> 📅<sub>6</sub>"
      assert html_response(conn, 200) =~ "Chapter2.Project1.Description"
      assert html_response(conn, 200) =~ "Chapter2.Project2.Name"
      assert html_response(conn, 200) =~ "⭐<sub>7</sub> 📅<sub>8</sub>"
      assert html_response(conn, 200) =~ "Chapter2.Project2.Description"

      refute html_response(conn, 200) =~ "Chapter3.Name"
      refute html_response(conn, 200) =~ "Chapter3.Description"
    end
  end

  test "GET /?&min_stars=5" do
    with_mock Awesome.Fetcher.API, get_data: &get_data/0 do
      conn = get(build_conn(), "/", %{"min_stars" => "5"})

      assert html_response(conn, 200) =~ "Awesome Elixir"
      refute html_response(conn, 200) =~ "Chapter1.Name"
      refute html_response(conn, 200) =~ "Chapter1.Description"
      refute html_response(conn, 200) =~ "Chapter1.Project1.Name"
      refute html_response(conn, 200) =~ "⭐<sub>1</sub> 📅<sub>2</sub>"
      refute html_response(conn, 200) =~ "Chapter1.Project1.Description"
      refute html_response(conn, 200) =~ "Chapter1.Project2.Name"
      refute html_response(conn, 200) =~ "⭐<sub>3</sub> 📅<sub>4</sub>"
      refute html_response(conn, 200) =~ "Chapter1.Project2.Description"

      assert html_response(conn, 200) =~ "Chapter2.Name"
      assert html_response(conn, 200) =~ "Chapter2.Description"
      assert html_response(conn, 200) =~ "Chapter2.Project1.Name"
      assert html_response(conn, 200) =~ "⭐<sub>5</sub> 📅<sub>6</sub>"
      assert html_response(conn, 200) =~ "Chapter2.Project1.Description"
      assert html_response(conn, 200) =~ "Chapter2.Project2.Name"
      assert html_response(conn, 200) =~ "⭐<sub>7</sub> 📅<sub>8</sub>"
      assert html_response(conn, 200) =~ "Chapter2.Project2.Description"

      refute html_response(conn, 200) =~ "Chapter3.Name"
      refute html_response(conn, 200) =~ "Chapter3.Description"
    end
  end
end
