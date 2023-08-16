defmodule Awesome.FetcherGetTest do
  use ExUnit.Case

  import Mock

  @markdown """
  There are [other sites with curated lists of elixir packages](#other-awesome-lists) which you can have a look at.

  - [Awesome Elixir](#awesome-elixir)
    - [Actors](#actors)
    - [Algorithms and Data structures](#algorithms-and-data-structures)
  - [Resources](#resources)
    - [Books](#books)

  ## Actors
  *Libraries and tools for working with actors and such.*
  * [alf](https://github.com/antonmi/ALF) - Flow-based Application Layer Framework.
  * [bpe](https://github.com/spawnproc/bpe) - Business Process Engine in Erlang. ([Doc](https://bpe.n2o.dev)).

  ## Algorithms and Data structures
  *Libraries and implementations of algorithms and data structures.*

  * [aja](https://github.com/sabiwara/aja) - High performance persistent vectors and ordered maps.
  * [array](https://github.com/takscape/elixir-array) - An Elixir wrapper library for Erlang's array.

  # Resources
  Various resources, such as books, websites and articles, for improving your Elixir development skills and knowledge.

  ## Books
  *Fantastic books and e-books.*

  * [Adopting Elixir](https://pragprog.com/book/tvmelixir/adopting-elixir) - Bring Elixir into your company, with real-life strategies from the people who built Elixir and use it successfully at scale. This book has all the information you need to take your application from concept to production (2017).
  """

  setup do
    on_exit(fn ->
      File.rm!("links_test.dets")
    end)
  end

  test "test fetcher" do
    with_mocks([
      {Awesome.Fetcher.Github.Adapter, [],
       request: fn _, _ ->
         {:ok, %{"content" => @markdown |> Base.encode64()}}
       end,
       get_project_miscs: fn _username, _project_name, _cache ->
         {:ok, %{"stars" => 10, "days_off" => 20}}
       end}
    ]) do
      {:ok, state} = Awesome.Fetcher.init([:test_ets, 'links_test.dets'])

      {:noreply, _state} = Awesome.Fetcher.handle_info(:refresh, state)

      [{:awesome, result}] = :ets.lookup(:test_ets, :awesome)

      assert [
               %{
                 descr:
                   {"p", [],
                    [
                      {"em", [], ["Libraries and tools for working with actors and such."], %{}}
                    ], %{}},
                 header: {"h2", [], ["Actors"], %{}},
                 projects:
                   {"ul", [],
                    [
                      {"li", [],
                       [
                         {"a", [{"href", "https://github.com/antonmi/ALF"}], ["alf"], %{}},
                         "⭐",
                         {"sub", [], ["10"], %{}},
                         "📅",
                         {"sub", [], ["20"], %{}},
                         " - Flow-based Application Layer Framework."
                       ], %{"days_off" => 20, "stars" => 10}},
                      {"li", [],
                       [
                         {"a", [{"href", "https://github.com/spawnproc/bpe"}], ["bpe"], %{}},
                         "⭐",
                         {"sub", [], ["10"], %{}},
                         "📅",
                         {"sub", [], ["20"], %{}},
                         " - Business Process Engine in Erlang. (",
                         {"a", [{"href", "https://bpe.n2o.dev"}], ["Doc"], %{}},
                         ")."
                       ], %{"days_off" => 20, "stars" => 10}}
                    ], %{}}
               },
               %{
                 descr:
                   {"p", [],
                    [
                      {"em", [],
                       ["Libraries and implementations of algorithms and data structures."], %{}}
                    ], %{}},
                 header: {"h2", [], ["Algorithms and Data structures"], %{}},
                 projects:
                   {"ul", [],
                    [
                      {"li", [],
                       [
                         {"a", [{"href", "https://github.com/sabiwara/aja"}], ["aja"], %{}},
                         "⭐",
                         {"sub", [], ["10"], %{}},
                         "📅",
                         {"sub", [], ["20"], %{}},
                         " - High performance persistent vectors and ordered maps."
                       ], %{"days_off" => 20, "stars" => 10}},
                      {"li", [],
                       [
                         {"a", [{"href", "https://github.com/takscape/elixir-array"}], ["array"],
                          %{}},
                         "⭐",
                         {"sub", [], ["10"], %{}},
                         "📅",
                         {"sub", [], ["20"], %{}},
                         " - An Elixir wrapper library for Erlang's array."
                       ], %{"days_off" => 20, "stars" => 10}}
                    ], %{}}
               }
             ] == result[:chapters]

      assert [
               %{
                 descr:
                   {"p", [],
                    [
                      {"em", [], ["Libraries and tools for working with actors and such."], %{}}
                    ], %{}},
                 header: {"h2", [], ["Actors"], %{}},
                 projects:
                   {"ul", [],
                    [
                      {"li", [],
                       [
                         {"a", [{"href", "https://github.com/antonmi/ALF"}], ["alf"], %{}},
                         "⭐",
                         {"sub", [], ["10"], %{}},
                         "📅",
                         {"sub", [], ["20"], %{}},
                         " - Flow-based Application Layer Framework."
                       ], %{"days_off" => 20, "stars" => 10}},
                      {"li", [],
                       [
                         {"a", [{"href", "https://github.com/spawnproc/bpe"}], ["bpe"], %{}},
                         "⭐",
                         {"sub", [], ["10"], %{}},
                         "📅",
                         {"sub", [], ["20"], %{}},
                         " - Business Process Engine in Erlang. (",
                         {"a", [{"href", "https://bpe.n2o.dev"}], ["Doc"], %{}},
                         ")."
                       ], %{"days_off" => 20, "stars" => 10}}
                    ], %{}}
               },
               %{
                 descr:
                   {"p", [],
                    [
                      {"em", [],
                       ["Libraries and implementations of algorithms and data structures."], %{}}
                    ], %{}},
                 header: {"h2", [], ["Algorithms and Data structures"], %{}},
                 projects:
                   {"ul", [],
                    [
                      {"li", [],
                       [
                         {"a", [{"href", "https://github.com/sabiwara/aja"}], ["aja"], %{}},
                         "⭐",
                         {"sub", [], ["10"], %{}},
                         "📅",
                         {"sub", [], ["20"], %{}},
                         " - High performance persistent vectors and ordered maps."
                       ], %{"days_off" => 20, "stars" => 10}},
                      {"li", [],
                       [
                         {"a", [{"href", "https://github.com/takscape/elixir-array"}], ["array"],
                          %{}},
                         "⭐",
                         {"sub", [], ["10"], %{}},
                         "📅",
                         {"sub", [], ["20"], %{}},
                         " - An Elixir wrapper library for Erlang's array."
                       ], %{"days_off" => 20, "stars" => 10}}
                    ], %{}}
               }
             ] == result[:chapters]

      assert %{
               body: [
                 {"li", [], [{"a", [{"href", "#actors"}], ["Actors"], %{}}], %{}},
                 {"li", [],
                  [
                    {"a", [{"href", "#algorithms-and-data-structures"}],
                     ["Algorithms and Data structures"], %{}}
                  ], %{}}
               ],
               wrapper:
                 {"ul", [],
                  [
                    {"li", [],
                     [
                       {"a", [{"href", "#awesome-elixir"}], ["Awesome Elixir"], %{}},
                       {"ul", [], [], %{}}
                     ], %{}},
                    {"li", [],
                     [
                       {"a", [{"href", "#resources"}], ["Resources"], %{}},
                       {"ul", [],
                        [{"li", [], [{"a", [{"href", "#books"}], ["Books"], %{}}], %{}}], %{}}
                     ], %{}}
                  ], %{}}
             } == result[:table_of_content]

      assert [
               {"p", [],
                [
                  "There are ",
                  {"a", [{"href", "#other-awesome-lists"}],
                   ["other sites with curated lists of elixir packages"], %{}},
                  " which you can have a look at."
                ], %{}}
             ] == result[:header]

      :dets.close('links_test.dets')
    end
  end
end
