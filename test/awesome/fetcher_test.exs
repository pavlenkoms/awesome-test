defmodule Awesome.FetcherTest do
  use ExUnit.Case

  @valid %{
    "Actors" => %{
      "description" => "*Libraries and tools for working with actors and such.*",
      "name" => "Actors",
      "projects" => %{
        "dflow" => %{
          "description" => "Pipelined flow processing engine.",
          "link" => "https://github.com/dalmatinerdb/dflow",
          "name" => "dflow"
        },
        "exactor" => %{
          "description" => "Helpers for easier implementation of actors in Elixir.",
          "link" => "https://github.com/sasa1977/exactor",
          "name" => "exactor"
        }
      },
      "reference" => "actors"
    },
    "Applications" => %{
      "description" => "*Standalone applications.*",
      "name" => "Applications",
      "projects" => %{
        "quiet_logger" => %{
          "description" =>
            "A simple plug to suppress health check logging (e.g.: when using Kubernetes).",
          "link" => "https://github.com/Driftrock/quiet_logger/pull/1",
          "name" => "quiet_logger"
        }
      },
      "reference" => "applications"
    }
  }

  defp check_fields(key, fields, a, b) do
    for el <- fields do
      path = [key, el]
      assert get_in(a, path) == get_in(b, path)
    end
  end

  defp check_links(first_links, second_links) do
    ziplist = Enum.zip(first_links, second_links)
    count1 = ziplist |> Enum.count()
    count2 = first_links |> Enum.count()
    count3 = second_links |> Enum.count()

    assert count1 == count2
    assert count2 == count3

    Enum.each(ziplist, fn {{url1, resp1, date1, iteration1}, {url2, resp2, date2, iteration2}} ->
      assert url1 == url2
      assert resp1 == resp2
      assert date1 == date2
      assert iteration1 + 1 == iteration2
    {{:iteration, iteration1}, {:iteration, iteration2}} ->
      assert iteration1 + 1 == iteration2
    end)
  end

  setup do
    on_exit(fn ->
      File.rm!("links_test.dets")
    end)
  end

  test "test fetcher" do
    {:ok, state} = Awesome.Fetcher.init([:test_ets, :test_links, 'links_test.dets', :test_pool])


    {:noreply, state} = Awesome.Fetcher.handle_info(:refresh, state)

    [{:awesome, result}] = :ets.lookup(:test_ets, :awesome)

    {:ok, _} = :dets.open_file(:test_links, file: 'links_test.dets')
    [_ | _] = first_links = :dets.foldl(fn link, acc -> [link | acc] end, [], :test_links)
    :dets.close(:test_links)

    {:noreply, _state} = Awesome.Fetcher.handle_info(:refresh, state)
    [{:awesome, new_result}] = :ets.lookup(:test_ets, :awesome)

    {:ok, _} = :dets.open_file(:test_links, file: 'links_test.dets')
    [_ | _] = second_links = :dets.foldl(fn link, acc -> [link | acc] end, [], :test_links)
    :dets.close(:test_links)

    check_links(first_links, second_links)

    assert map_size(result) == 2
    assert map_size(new_result) == 2

    fields = ~w(description name reference)

    check_fields("Actors", fields, result, @valid)
    check_fields("Applications", fields, result, @valid)
    check_fields("Actors", fields, new_result, @valid)
    check_fields("Applications", fields, new_result, @valid)

    fields = ~w(description name link)

    projects = get_in(result, ~w(Actors projects))
    new_projects = get_in(new_result, ~w(Actors projects))
    vprojects = get_in(@valid, ~w(Actors projects))
    assert map_size(projects) == 2
    assert map_size(new_projects) == 2
    check_fields("dflow", fields, projects, vprojects)
    check_fields("exactor", fields, projects, vprojects)
    check_fields("dflow", fields, new_projects, vprojects)
    check_fields("exactor", fields, new_projects, vprojects)

    projects = get_in(result, ~w(Applications projects))
    new_projects = get_in(new_result, ~w(Applications projects))
    vprojects = get_in(@valid, ~w(Applications projects))
    assert map_size(projects) == 1
    assert map_size(new_projects) == 1

    check_fields("quiet_logger", fields, projects, vprojects)
    check_fields("quiet_logger", fields, new_projects, vprojects)
  end
end
