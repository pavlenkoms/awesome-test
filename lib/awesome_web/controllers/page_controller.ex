defmodule AwesomeWeb.PageController do
  use AwesomeWeb, :controller

  def index(conn, params) do
    data =
      case Awesome.Fetcher.get_data(params) do
        {:ok, data} ->
          Earmark.Transform.transform(data)

        _ ->
          ""
      end

    render(conn, "index.html", data: data)
  end
end
