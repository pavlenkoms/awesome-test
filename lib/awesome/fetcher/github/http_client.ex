defmodule Awesome.Fetcher.Github.HttpClient do
  use Tesla

  @default_headers [{"User-Agent", "Awesome-Test-App"}]

  def get(client, path) do
    Tesla.get(client, "/" <> path)
  end

  def client(headers) do
    token = token()

    middleware =
      [
        {Tesla.Middleware.BaseUrl, "https://api.github.com/repos"},
        Tesla.Middleware.JSON,
        Tesla.Middleware.FollowRedirects,
        {Tesla.Middleware.Headers, @default_headers ++ headers}
      ] ++
        if token do
          [{Tesla.Middleware.BearerAuth, token: token}]
        else
          []
        end

    Tesla.client(middleware)
  end

  def token() do
    Application.get_env(:awesome, __MODULE__)[:token]
  end
end
