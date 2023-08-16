defmodule Awesome.Fetcher.Gitlab.Adapter do
  alias Awesome.Fetcher.Gitlab.HttpClient

  require Logger

  @path_to_main "/repository/branches/main"
  @path_to_master "/repository/branches/master"

  def request(path) do
    []
    |> HttpClient.client()
    |> HttpClient.get(path)
    |> case do
      {:ok, %{status: 200, body: resp_body}} ->
        Logger.info("updated #{path}")
        {:ok, resp_body}

      {:ok, %{status: 403, headers: headers, body: resp_body}} ->
        case List.keyfind(headers, "ratelimit-remaining", 0) do
          nil ->
            {:error, resp_body}

          {"ratelimit-remaining", "0"} ->
            {_, time} =
              List.keyfind(
                headers,
                "ratelimit-reset",
                0,
                {"ratelimit-reset",
                 DateTime.utc_now() |> DateTime.to_unix() |> Integer.to_string()}
              )

            {:error, :rate_limit, String.to_integer(time)}
        end

      {:ok, %{status: 404}} ->
        {:error, :not_found}

      {:ok, %{body: resp_body}} ->
        {:error, resp_body}

      {:error, %{reason: reason}} ->
        {:error, reason}
    end
  end

  def get_project_miscs(username, project_name) do
    path = username <> "/" <> project_name
    path = URI.encode_www_form(path)

    with {:ok, resp} <- request(path),
         {:ok, last_commit} <- get_last_commit(path) do
      {:ok, last_commit_date, _} =
        last_commit
        |> get_in(~w(commit committed_date))
        |> DateTime.from_iso8601()

      days_off = last_commit_date && DateTime.diff(DateTime.utc_now(), last_commit_date, :day)

      {:ok,
       %{
         "stars" => resp["star_count"],
         "days_off" => days_off
       }}
    end
  end

  defp get_last_commit(path) do
    case request(path <> @path_to_main) do
      {:error, :not_found} ->
        request(path <> @path_to_master)

      resp ->
        resp
    end
  end
end
