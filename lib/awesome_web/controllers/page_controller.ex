defmodule AwesomeWeb.PageController do
  use AwesomeWeb, :controller

  def index(conn, params) do
    data =
      Awesome.Fetcher.API.get_data()
      |> filter_data(params)

    render(conn, "index.html", data: data)
  end

  # А вот если бы не поленился завести экту, то всё это добро можно было бы
  # свесить на БД и что бы она уже отжималась с фильтрациями.

  defp filter_data(data, %{"min_stars" => min_stars}) do
    min_stars =
      case Integer.parse(min_stars) do
        :error -> 0
        {ms, _} -> ms
      end

    Enum.reduce(data, %{}, fn {name, chapter}, acc ->
      chapter["projects"]
      |> Enum.filter(fn {_, project} ->
        project["stars"] >= min_stars
      end)
      |> Map.new()
      |> case do
        projects when map_size(projects) == 0 ->
          acc

        projects ->
          chapter = Map.put(chapter, "projects", projects)
          Map.put(acc, name, chapter)
      end
    end)
  end

  defp filter_data(data, _) do
    data
  end
end
