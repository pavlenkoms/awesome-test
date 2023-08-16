defmodule Awesome.Fetcher.Gitlab.HttpClient do
  use Tesla

  @user Application.compile_env(:awesome, __MODULE__)[:username]
  @password Application.compile_env(:awesome, __MODULE__)[:password]
  @default_headers (@user &&
                      [{"Authorization", "Basic " <> Base.encode64("#{@user}:#{@password}")}]) ||
                     []

  def get(client, path) do
    Tesla.get(client, "/" <> path)
  end

  def client(headers) do
    middleware = [
      {Tesla.Middleware.BaseUrl, "https://gitlab.com/api/v4/projects"},
      Tesla.Middleware.JSON,
      Tesla.Middleware.FollowRedirects,
      {Tesla.Middleware.Headers, @default_headers ++ headers}
    ]

    Tesla.client(middleware)
  end
end
