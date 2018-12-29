defmodule Awesome.Fetcher do
  use GenServer

  require Logger


  # Ошибка раз: без экты. С эктой структура данных была бы прозрачнее, и код
  # читаемее, т.к. реляции в структуре листа приложений просматриваются ну очень
  # явно + было бы возможно слегка кофортнее тестить.
  # Ошибка два: детска не самый лучший вариант в принципе, но для таких микро
  # проектов сканает. Как альтернативу было бы гуд юзать какую нить опять же
  # постгрю под эктой али редис какой


  @api_link "https://api.github.com/repos/"
  @awesome_path Application.get_env(:awesome, __MODULE__)[:awesome_path]
  @readme Application.get_env(:awesome, __MODULE__)[:readme]

  @last_commit "/commits/master"

  @update_interval 24 * 60 * 60 * 1000
  @data_key :awesome

  @user Application.get_env(:awesome, __MODULE__)[:username]
  @password Application.get_env(:awesome, __MODULE__)[:password]
  @basic_auth (@user && [basic_auth: {@user, @password}]) || []
  @pool_name :awesome_pool
  @awesome_storage :awesome_storage

  def get_data() do
    case :ets.lookup(@awesome_storage, @data_key) do
      [] -> %{}
      [{@data_key, data}] -> data
    end
  end

  def start_link(_) do
    args = [
      @awesome_storage,
      :links_table,
      Application.get_env(:awesome, Awesome.Fetcher)[:links_dets],
      @pool_name
    ]

    start_link(args, Mix.env())
  end

  # Говно. Но пресловутый автоапдейт
  def start_link(_, :test) do
    {
      :ok,
      spawn_link(fn ->
        receive do
          _ ->
            :ok
        end
      end)
    }
  end

  def start_link(args, _) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def start_link(ets_name, links_table, links_dets, pool_name) do
    GenServer.start_link(__MODULE__, [ets_name, links_table, links_dets, pool_name])
  end

  def init([ets_name, links_table, links_dets, pool_name]) do
    options = [{:timeout, 150_000}, {:max_connections, 6}]
    :ok = :hackney_pool.start_pool(pool_name, options)
    storage = :ets.new(ets_name, [:set, :protected, :named_table])

    send(self(), :refresh)

    {:ok,
     %{
       storage: storage,
       iteration: 0,
       links_table: links_table,
       links_dets: links_dets,
       pool_name: pool_name
     }}
  end

  def handle_info(:refresh, state) do
    {:ok, _} = :dets.open_file(state.links_table, file: state.links_dets)

    iteration =
      case :dets.lookup(state.links_table, :iteration) do
        [{:iteration, iter}] ->
          iter

        _ ->
          :dets.insert(state.links_table, {:iteration, state.iteration})
          0
      end

    state = %{state | iteration: iteration}

    with {:ok, body} <- do_http_request(@api_link <> @awesome_path <> @readme, state),
         # тут бы по хорошему надо определять тип
         # контетна, но чето как то лень. Пусть будеть base64 всегда.
         {:ok, readme} <- Base.decode64(body["content"], ignore: :whitespace),
         {:ok, data} <- parse_readme(readme, state),
         :ok <- links_garbage_collect(state),
         true <- :ets.insert(state.storage, {@data_key, data}) do
      :timer.send_after(@update_interval, :refresh)
      iteration = :dets.update_counter(state.links_table, :iteration, {2, 1})
      :dets.sync(state.links_table)
      :dets.close(state.links_table)

      {:noreply, %{state | iteration: iteration}}
    else
      {:error, :x_rate_limit, reset} ->
        now = DateTime.utc_now() |> DateTime.to_unix()
        diff = reset - now

        timeout =
          cond do
            diff < 0 -> 1000
            true -> diff * 1000
          end

        Logger.error("X-rate-limit, waiting #{timeout / 1000} secs...")

        :timer.send_after(timeout, :refresh)
        {:noreply, state}

      err ->
        :timer.sleep(3000)
        Logger.error("Something goes wrong #{inspect(err)}")
        :timer.send_after(10000, :refresh)
        {:noreply, state}
    end
  end

  defp parse_readme(readme, state) do
    regexp = ~r/- \[Awesome Elixir\]\(#awesome-elixir\)\n(?<chapters>[\s\S]*?)\n(- \[|\n)/

    with %{"chapters" => chapter_names_string} <- Regex.named_captures(regexp, readme),
         splitted_chapter_names <- String.split(chapter_names_string, "\n"),
         {:ok, chapter_names} <- parse_chapters(splitted_chapter_names),
         {:ok, chapters} <- get_chapters(chapter_names, readme),
         {:ok, detailed_chapters} <- fetch_chapters_details(chapters, state) do
      map = for chapter <- detailed_chapters, into: %{}, do: {chapter["name"], chapter}
      {:ok, map}
    end
  end

  defp parse_chapters(splitted_chapter_names) do
    regexp = ~r/- \[(?<chapter_name>.+)\]\(#(?<chapter_ref>.+)\)/

    Enum.reduce_while(splitted_chapter_names, {:ok, []}, fn str, {:ok, acc} ->
      case Regex.named_captures(regexp, str) do
        %{"chapter_name" => _} = capture -> {:cont, {:ok, [capture | acc]}}
        _ -> {:halt, {:error, {:bad_chapter_name, str}}}
      end
    end)
  end

  defp get_chapters(chapter_names, readme) do
    Enum.reduce_while(chapter_names, {:ok, []}, fn chapter, {:ok, acc} ->
      %{"chapter_name" => name, "chapter_ref" => ref} = chapter

      regexp = ~r/## #{Regex.escape(name)}\n+(?<description>.*?)\n+(?<projects>(\* .+\n)+)\n+/

      with %{} = captures <- Regex.named_captures(regexp, readme),
           {:ok, projects} <- parse_projects(captures["projects"]) do
        captures =
          captures
          |> Map.put("name", name)
          |> Map.put("reference", ref)
          |> Map.put("projects", projects)

        {:cont, {:ok, [captures | acc]}}
      else
        nil ->
          Logger.warn("Bad chapter format #{inspect(chapter)}")
          {:cont, {:ok, acc}}

        err ->
          {:halt, err}
      end
    end)
  end

  defp parse_projects(links) do
    regexp = ~r/\* \[(?<name>.+)\]\((?<link>.+)\) - (?<description>.+)/

    links
    |> String.split("\n")
    |> Enum.reduce_while({:ok, []}, fn
      "", acc ->
        {:cont, acc}

      str, {:ok, acc} ->
        case Regex.named_captures(regexp, str) do
          %{} = project ->
            {:cont, {:ok, [project | acc]}}

          nil ->
            Logger.warn("Bad project format: #{inspect(str)}")
            {:cont, {:ok, acc}}
        end
    end)
  end

  defp fetch_chapters_details(chapters, state) do
    Enum.reduce_while(chapters, {:ok, []}, fn chapter, {:ok, acc} ->
      with projects <- fetch_projects_details(chapter["projects"], state),
           :ok <- check_rate_limit(projects) do
        projects = for project <- projects, into: %{}, do: {project["name"], project}

        acc =
          if map_size(projects) == 0 do
            acc
          else
            [Map.put(chapter, "projects", projects) | acc]
          end

        {:cont, {:ok, acc}}
      else
        err ->
          {:halt, err}
      end
    end)
  end

  defp fetch_projects_details(projects, state) do
    projects
    |> Enum.map(&Task.async(fn -> fetch_project_details(&1, state) end))
    |> Enum.flat_map(fn task ->
      case Task.await(task, 60000) do
        nil -> []
        res -> [res]
      end
    end)
  end

  defp fetch_project_details(project, state) do
    regexp = ~r/github.com\/(?<username>.+?)\/(?<project_name>.+?)($|\/.*)/

    with %{"username" => username, "project_name" => project_name} <-
           Regex.named_captures(regexp, project["link"]),
         {:ok, project} <- get_project_miscs(project, username, project_name, state) do
      project
    else
      {:error, :x_rate_limit, _} = err ->
        err

      err ->
        Logger.warn(
          "Something bad in fetching info for project #{project["name"]}: #{inspect(err)}\n\t#{
            inspect(project)
          }"
        )

        nil
    end
  end

  def get_project_miscs(project, username, project_name, state) do
    with {:ok, status} <- do_http_request(@api_link <> username <> "/" <> project_name, state),
         {:ok, last_commit} <-
           do_http_request(
             @api_link <> username <> "/" <> project_name <> @last_commit,
             state
           ) do
      {:ok, last_commit_date, _} =
        last_commit
        |> get_in(~w(commit author date))
        |> DateTime.from_iso8601()

      seconds_off =
        last_commit_date && DateTime.diff(DateTime.utc_now(), last_commit_date, :second)

      project =
        project
        |> Map.put("stars", status["stargazers_count"])
        |> Map.put("seconds_off", seconds_off)

      {:ok, project}
    end
  end

  defp check_rate_limit([]), do: :ok
  defp check_rate_limit([{:error, :x_rate_limit, _} = err | _]), do: err
  defp check_rate_limit([_ | tail]), do: check_rate_limit(tail)

  defp do_http_request(url, state) do
    options = [
      hackney:
        [
          pool: state.pool_name,
          follow_redirect: true,
          checkout_timeout: 20000
        ] ++ @basic_auth
    ]

    stored = :dets.lookup(state.links_table, url)
    headers = make_headers(stored)

    case HTTPoison.get(url, headers, options) do
      {:ok, %{status_code: 200, body: resp_body, headers: headers}} ->
        Logger.info("updated #{url}")
        {_, date} = List.keyfind(headers, "Date", 0, {"Date", nil})
        resp = Jason.decode!(resp_body)
        :dets.insert(state.links_table, {url, resp, date, state.iteration})
        {:ok, resp}

      {:ok, %{status_code: 304}} ->
        Logger.info("cached #{url}")
        [{^url, resp, date, _}] = stored
        :dets.insert(state.links_table, {url, resp, date, state.iteration})
        {:ok, resp}

      {:ok, %{status_code: 403, header: headers, body: resp_body}} ->
        case List.keyfind(headers, "X-RateLimit-Remaining", 0) do
          nil ->
            {:error, resp_body}

          {"X-RateLimit-Remaining", "0"} ->
            {_, time} =
              List.keyfind(
                headers,
                "X-RateLimit-Remaining",
                0,
                {"X-RateLimit-Remaining",
                 DateTime.utc_now() |> DateTime.to_unix() |> Integer.to_string()}
              )

            {:error, :x_rate_limit, String.to_integer(time)}
        end

      {:ok, %{body: resp_body}} ->
        {:error, resp_body}

      {:error, %{reason: reason}} ->
        {:error, reason}
    end
  end

  defp make_headers([{_, _, date, _}]) do
    [{"If-Modified-Since", date}]
  end

  defp make_headers(_), do: []

  defp links_garbage_collect(state) do
    :dets.select_delete(state.links_table, [
      {{:_, :_, :_, :"$1"}, [{:<, :"$1", state.iteration}], [true]}
    ])

    :ok
  end
end
