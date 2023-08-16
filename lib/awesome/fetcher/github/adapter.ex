defmodule Awesome.Fetcher.Github.Adapter do
  alias Awesome.Fetcher.Github.HttpClient
  alias Awesome.Fetcher.PersistCache

  require Logger

  @last_commit_master "/commits/master"
  @last_commit_main "/commits/main"

  def request(path, cache) do
    cache_key = key(path)
    {_, data} = PersistCache.get(cache, cache_key)
    PersistCache.touch(cache, cache_key)

    data
    |> make_headers()
    |> HttpClient.client()
    |> HttpClient.get(path)
    |> case do
      {:ok, %{status: 200, body: resp_body, headers: headers}} ->
        Logger.info("updated #{path}")
        {_, date} = List.keyfind(headers, "last-modified", 0, {"last-modified", nil})
        {_, etag} = List.keyfind(headers, "etag", 0, {"etag", nil})
        PersistCache.put(cache, cache_key, {resp_body, date, etag})
        {:ok, resp_body}

      {:ok, %{status: 304}} ->
        Logger.info("cached #{path}")
        {resp_body, _, _} = data
        {:ok, resp_body}

      {:ok, %{status: 404, headers: headers, body: resp_body} = resp} ->
        {:error, :not_found}

      {:ok, %{status: 403, headers: headers, body: resp_body}} ->
        case List.keyfind(headers, "x-ratelimit-remaining", 0) do
          nil ->
            {:error, resp_body}

          {"x-ratelimit-remaining", "0"} ->
            {_, time} =
              List.keyfind(
                headers,
                "x-ratelimit-reset",
                0,
                {"x-ratelimit-reset",
                 DateTime.utc_now() |> DateTime.to_unix() |> Integer.to_string()}
              )

            {:error, :rate_limit, String.to_integer(time)}
        end

      {:ok, %{status: 422}} ->
        {:error, :unprocessable_entity}

      {:ok, %{body: resp_body}} ->
        {:error, resp_body}

      {:error, %{reason: reason}} ->
        {:error, reason}
    end
  end

  def get_project_miscs(username, project_name, cache) do
    path = username <> "/" <> project_name

    with {:ok, resp} <- request(path, cache) do
      # да, некрасиво, но я уже устал
      {:ok, last_commit_date, _} =
        try do
          DateTime.from_iso8601(resp["pushed_at"])
        rescue
          e ->
            {:ok, DateTime.utc_now(), 0}
        end

      days_off = last_commit_date && DateTime.diff(DateTime.utc_now(), last_commit_date, :day)

      {:ok,
       %{
         "stars" => resp["stargazers_count"],
         "days_off" => days_off
       }}
    end
  end

  defp get_last_commit(path, cache) do
    case request(path <> @last_commit_main, cache) do
      {:error, :unprocessable_entity} ->
        request(path <> @last_commit_master, cache)

      resp ->
        resp
    end
  end

  defp make_headers(nil), do: []

  defp make_headers({_, date, etag}) do
    if(date, do: [{"If-Modified-Since", date}], else: []) ++
      if etag, do: [{"If-None-Match", etag}], else: []
  end

  defp make_headers(_), do: []

  defp key(path) do
    {:github, path}
  end
end
