defmodule Awesome.Fetcher.Processor do
  alias Awesome.Fetcher.Github
  alias Awesome.Fetcher.Gitlab

  require Logger

  def process_chapters(%{chapters: {:error, _} = error} = _parse_state, _) do
    error
  end

  def process_chapters(%{chapters: chapters} = parse_state, cache) do
    {chapters, errors} =
      Enum.reduce(chapters, {[], []}, fn chapter, {acc, errors} ->
        {projects, new_errors} = process_projects(chapter.projects, cache)

        {acc ++ [%{chapter | projects: projects}], errors ++ new_errors}
      end)

    {%{parse_state | chapters: chapters}, errors}
  end

  defp process_projects(projects, cache) do
    {ul_tag, ul_attrs, lines, ul_meta} = projects

    line_process_fun = fn line ->
      {:ok, line}

      try do
        with {:ok, data} <- parse_line(line),
             {:ok, misc} <- get_misc(data, cache) do
          line = inject_misc(line, misc)
          {:ok, line}
        else
          {:error, :unmatched} ->
            {:ok, line}

          {:error, :unknown_vcs} ->
            {:ok, line}

          {:error, :not_found} ->
            {:ok, line}

          error ->
            error
        end
      rescue
        error ->
          Logger.error(Exception.format(:error, error, __STACKTRACE__))
          {:error, error}
      end
    end

    {lines, errors} =
      lines
      |> Enum.map(&Task.async(fn -> line_process_fun.(&1) end))
      |> Enum.flat_map(fn task ->
        case Task.await(task, 60000) do
          nil -> []
          res -> [res]
        end
      end)
      |> Enum.reduce({[], []}, fn
        {:ok, line}, {acc, errors} ->
          {acc ++ [line], errors}

        error, {acc, errors} ->
          {acc, [error | errors]}
      end)

    projects = {ul_tag, ul_attrs, lines, ul_meta}
    {projects, errors}
  end

  defp parse_line(line) do
    {_, _, [{_, [{"href", link}], _, _} | _], _} = line

    regexp = ~r/https\:\/\/(?<vcs>.+?)\/(?<username>.+?)\/(?<project_name>[^#]+)/

    case Regex.named_captures(regexp, link) do
      nil -> {:error, :unmatched}
      data -> {:ok, data}
    end
  end

  defp inject_misc(line, misc) do
    {li_tag, li_attrs, [{a_tag, [{"href", _}] = href, name, meta}, descr | tail], _} = line

    sub_stars = {"sub", [], ["#{misc["stars"]}"], %{}}
    sub_daysoff = {"sub", [], ["#{misc["days_off"]}"], %{}}

    {li_tag, li_attrs,
     [{a_tag, href, name, meta}, "⭐", sub_stars, "📅", sub_daysoff, descr | tail], misc}
  end

  defp get_misc(data, cache) do
    case data["vcs"] do
      "github.com" ->
        Github.Adapter.get_project_miscs(data["username"], data["project_name"], cache)

      "gitlab.com" ->
        Gitlab.Adapter.get_project_miscs(data["username"], data["project_name"])

      _ ->
        {:error, :unknown_vcs}
    end
  end
end
