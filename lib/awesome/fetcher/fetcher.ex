defmodule Awesome.Fetcher do
  # я не знаю что я обожаю больше. Парсить и модифицировать строки или же
  # работать с глубоко-вложенными структурами данных
  use GenServer

  require Logger

  alias Awesome.Fetcher.Github
  alias Awesome.Fetcher.Processor
  alias Awesome.Fetcher.PersistCache

  @awesome_path Application.compile_env(:awesome, __MODULE__)[:awesome_path]
  @readme Application.compile_env(:awesome, __MODULE__)[:readme]

  @update_interval 24 * 60 * 60 * 1000
  @data_key :awesome
  @awesome_storage :awesome_storage

  def get_data(params) do
    case :ets.lookup(@awesome_storage, @data_key) do
      [] ->
        :not_found

      [{@data_key, data}] ->
        data =
          data
          |> filter_data(params)
          |> compile_ast()

        {:ok, data}
    end
  end

  def start_link(_) do
    args = [
      @awesome_storage,
      Application.get_env(:awesome_megafon, __MODULE__)[:cache_file]
    ]

    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([ets_name, cache_file]) do
    storage = :ets.new(ets_name, [:set, :protected, :named_table])

    send(self(), :refresh)

    {:ok,
     %{
       storage: storage,
       cache_file: cache_file
     }}
  end

  def handle_info(:refresh, state) do
    # для персиста использовал детс, т.к. тащить что то еще было лень
    {:ok, cache} = PersistCache.create(state.cache_file)

    try do
      with {:ok, body} <- Github.Adapter.request(@awesome_path <> @readme, cache),
           {:ok, readme} <- Base.decode64(body["content"], ignore: :whitespace),
           {markdown_ast, errors} <- parse_readme(readme, cache),
           :ok <- PersistCache.collect_garbage(cache),
           true <- :ets.insert(state.storage, {@data_key, markdown_ast}) do
        send_refresh(errors)
      else
        {:error, :rate_limit, reset} ->
          timeout = calculate_limit_timeout(reset)

          Logger.error("ratelimit, waiting #{timeout / 1000} secs...")

          :timer.send_after(timeout, :refresh)

        err ->
          Logger.error("Something goes wrong #{inspect(err)}")
          :timer.send_after(10000, :refresh)
      end
    rescue
      error ->
        Logger.error(Exception.format(:error, error, __STACKTRACE__))
        send_refresh([])
    end

    PersistCache.close(cache)

    {:noreply, state}
  end

  defp send_refresh([]), do: :timer.send_after(@update_interval, :refresh)

  defp send_refresh(errors) do
    errors
    |> Enum.filter(fn
      {:error, :rate_limit, _} -> true
      _ -> false
    end)
    |> case do
      [] ->
        :timer.send_after(10000, :refresh)

      [{:error, :rate_limit, reset} | _] ->
        timeout = calculate_limit_timeout(reset)
        Logger.error("ratelimit, waiting #{timeout / 1000} secs...")
        :timer.send_after(timeout, :refresh)
    end
  end

  defp calculate_limit_timeout(reset) do
    now = DateTime.utc_now() |> DateTime.to_unix()
    diff = reset - now

    timeout =
      cond do
        diff < 0 -> 1000
        true -> diff * 1000
      end

    timeout
  end

  defp parse_readme(readme, cache) do
    readme
    |> EarmarkParser.as_ast()
    |> process_ast(cache)
  end

  defp process_ast({:ok, ast, _}, cache) do
    parse_state = %{
      ast: ast,
      header: [],
      table_of_content: %{
        wrapper: nil,
        body: nil
      },
      chapters: [],
      tail: []
    }

    parse_state
    |> get_header()
    |> get_table_of_content()
    |> get_chapters()
    |> get_tail()
    |> Processor.process_chapters(cache)
  end

  defp get_header(%{ast: ast} = state) do
    {header, tail} =
      Enum.split_while(ast, fn
        {"ul", _, _, _} -> false
        _ -> true
      end)

    %{state | ast: tail, header: header}
  end

  defp get_table_of_content(%{ast: [elem | tail]} = state) do
    {ul_tag1, ul_attrs1, chapters, ul_meta1} = elem
    [awesome_li | chapters_tail] = chapters
    {li_tag, li_attrs, [awesome_link, awesome_ul], li_meta} = awesome_li
    {ul_tag2, ul_attrs2, awesome_list, ul_meta2} = awesome_ul

    awesome_li = {li_tag, li_attrs, [awesome_link, {ul_tag2, ul_attrs2, [], ul_meta2}], li_meta}
    chapters = [awesome_li | chapters_tail]
    elem = {ul_tag1, ul_attrs1, chapters, ul_meta1}

    table_of_content = %{
      wrapper: elem,
      body: awesome_list
    }

    %{state | ast: tail, table_of_content: table_of_content}
  end

  defp get_chapters(%{ast: ast} = state) do
    {content, tail} =
      Enum.split_while(ast, fn
        {"h1", _, _, _} -> false
        _ -> true
      end)

    chapters = parse_content(content, [])

    %{state | ast: tail, chapters: chapters}
  end

  defp get_tail(%{ast: ast} = state) do
    %{state | ast: [], tail: ast}
  end

  defp parse_content([], list), do: list

  defp parse_content(ast, list) do
    {ast,
     %{
       header: nil,
       descr: nil,
       projects: nil
     }}
    |> get_content_header()
    |> get_descr()
    |> get_projects()
    |> case do
      {:ok, {ast, element}} ->
        parse_content(ast, list ++ [element])

      err ->
        err
    end
  end

  defp get_content_header({ast, element}) do
    ast
    |> Enum.drop_while(fn
      {"h2", _, _, _} -> false
      _ -> true
    end)
    |> case do
      [] ->
        {:error, :parse_error}

      [header | tail] ->
        {:ok, {tail, %{element | header: header}}}
    end
  end

  defp get_descr({:error, _} = error), do: error

  defp get_descr({:ok, {ast, element}}) do
    ast
    |> Enum.drop_while(fn
      {"p", _, _, _} -> false
      _ -> true
    end)
    |> case do
      [] ->
        {:error, :parse_error}

      [descr | tail] ->
        {:ok, {tail, %{element | descr: descr}}}
    end
  end

  defp get_projects({:error, _} = error), do: error

  defp get_projects({:ok, {ast, element}}) do
    ast
    |> Enum.drop_while(fn
      {"ul", _, _, _} -> false
      _ -> true
    end)
    |> case do
      [] ->
        {:error, :parse_error}

      [projects | tail] ->
        {:ok, {tail, %{element | projects: projects}}}
    end
  end

  defp compile_ast(parse_state) do
    ast =
      parse_state[:header] ++
        build_table_of_content(parse_state[:table_of_content]) ++
        build_chapters(parse_state[:chapters]) ++ parse_state[:tail]

    fun = fn
      {"h" <> _, _, [h_body], _} = n ->
        Earmark.AstTools.merge_atts_in_node(n, id: Recase.to_kebab(h_body))

      string ->
        string
    end

    Earmark.Transform.map_ast(ast, fun)
  end

  defp build_table_of_content(table_of_content) do
    %{
      wrapper: wrapper,
      body: body
    } = table_of_content

    {ul_tag1, ul_attrs1, chapters, ul_meta1} = wrapper
    [awesome_li | chapters_tail] = chapters
    {li_tag, li_attrs, [awesome_link, awesome_ul], li_meta} = awesome_li
    {ul_tag2, ul_attrs2, _, ul_meta2} = awesome_ul

    awesome_li = {li_tag, li_attrs, [awesome_link, {ul_tag2, ul_attrs2, body, ul_meta2}], li_meta}
    chapters = [awesome_li | chapters_tail]

    [{ul_tag1, ul_attrs1, chapters, ul_meta1}]
  end

  defp build_chapters(chapters) do
    chapters
    |> Enum.flat_map(fn chapter ->
      {h_tag, _, [h_body], meta} = chapter[:header]
      [chapter[:header], chapter[:descr], chapter[:projects]]
    end)
  end

  defp filter_data(parse_state, %{"min_stars" => min_stars}) do
    min_stars =
      case Integer.parse(min_stars) do
        :error -> 0
        {ms, _} -> ms
      end

    chapters = filter_projects_by_min_stars(parse_state[:chapters], min_stars)
    {chapters_to_save, chapters_to_delete} = split_chapters(chapters)
    table_of_content = filter_table_of_content(parse_state[:table_of_content], chapters_to_delete)

    %{parse_state | table_of_content: table_of_content, chapters: chapters_to_save}
  end

  defp filter_data(parse_state, _) do
    parse_state
  end

  defp filter_projects_by_min_stars(chapters, min_stars) do
    Enum.reduce(chapters, [], fn chapter, acc ->
      %{
        projects: projects
      } = chapter

      {ul_tag, ul_attrs, lines, ul_meta} = projects

      lines =
        Enum.filter(lines, fn
          {_, _, _, %{"stars" => stars}} ->
            min_stars <= stars

          _ ->
            false
        end)

      projects = {ul_tag, ul_attrs, lines, ul_meta}

      acc ++ [%{chapter | projects: projects}]
    end)
  end

  defp split_chapters(chapters) do
    Enum.split_with(chapters, fn chapter ->
      %{
        projects: {_ul_tag, _ul_attrs, lines, _ul_meta}
      } = chapter

      lines != []
    end)
  end

  defp filter_table_of_content(table_of_content, chapters_to_delete) do
    %{
      body: body
    } = table_of_content

    chapter_names =
      Enum.map(chapters_to_delete, fn ch ->
        {_, _, name, _} = ch[:header]
        name
      end)

    body =
      Enum.filter(body, fn chapter_link ->
        {_, _, [{_, _, name, _} | _], _} = chapter_link
        name not in chapter_names
      end)

    %{table_of_content | body: body}
  end
end
