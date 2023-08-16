defmodule Awesome.FetcherRenderTest do
  use ExUnit.Case

  @ast_struct %{
    ast: [],
    chapters: [
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
                {"sub", [], ["20"], %{}},
                "📅",
                {"sub", [], ["20"], %{}},
                " - Business Process Engine in Erlang. (",
                {"a", [{"href", "https://bpe.n2o.dev"}], ["Doc"], %{}},
                ")."
              ], %{"days_off" => 20, "stars" => 20}}
           ], %{}}
      },
      %{
        descr:
          {"p", [],
           [
             {"em", [], ["Libraries and implementations of algorithms and data structures."], %{}}
           ], %{}},
        header: {"h2", [], ["Algorithms and Data structures"], %{}},
        projects:
          {"ul", [],
           [
             {"li", [],
              [
                {"a", [{"href", "https://github.com/sabiwara/aja"}], ["aja"], %{}},
                "⭐",
                {"sub", [], ["30"], %{}},
                "📅",
                {"sub", [], ["20"], %{}},
                " - High performance persistent vectors and ordered maps."
              ], %{"days_off" => 20, "stars" => 30}},
             {"li", [],
              [
                {"a", [{"href", "https://github.com/takscape/elixir-array"}], ["array"], %{}},
                "⭐",
                {"sub", [], ["40"], %{}},
                "📅",
                {"sub", [], ["20"], %{}},
                " - An Elixir wrapper library for Erlang's array."
              ], %{"days_off" => 20, "stars" => 40}}
           ], %{}}
      }
    ],
    header: [
      {"p", [],
       [
         "There are ",
         {"a", [{"href", "#other-awesome-lists"}],
          ["other sites with curated lists of elixir packages"], %{}},
         " which you can have a look at."
       ], %{}}
    ],
    table_of_content: %{
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
              {"ul", [], [{"li", [], [{"a", [{"href", "#books"}], ["Books"], %{}}], %{}}], %{}}
            ], %{}}
         ], %{}}
    },
    tail: [
      {"h1", [], ["Resources"], %{}},
      {"p", [],
       [
         "Various resources, such as books, websites and articles, for improving your Elixir development skills and knowledge."
       ], %{}},
      {"h2", [], ["Books"], %{}},
      {"p", [], [{"em", [], ["Fantastic books and e-books."], %{}}], %{}}
    ]
  }

  setup do
    :ok
  end

  test "result" do
    _storage = :ets.new(:awesome_storage, [:set, :protected, :named_table])
    :ets.insert(:awesome_storage, {:awesome, @ast_struct})

    assert {:ok,
            [
              {"p", [],
               [
                 "There are ",
                 {"a", [{"href", "#other-awesome-lists"}],
                  ["other sites with curated lists of elixir packages"], %{}},
                 " which you can have a look at."
               ], %{}},
              {"ul", [],
               [
                 {"li", [],
                  [
                    {"a", [{"href", "#awesome-elixir"}], ["Awesome Elixir"], %{}},
                    {"ul", [],
                     [
                       {"li", [], [{"a", [{"href", "#actors"}], ["Actors"], %{}}], %{}},
                       {"li", [],
                        [
                          {"a", [{"href", "#algorithms-and-data-structures"}],
                           ["Algorithms and Data structures"], %{}}
                        ], %{}}
                     ], %{}}
                  ], %{}},
                 {"li", [],
                  [
                    {"a", [{"href", "#resources"}], ["Resources"], %{}},
                    {"ul", [], [{"li", [], [{"a", [{"href", "#books"}], ["Books"], %{}}], %{}}],
                     %{}}
                  ], %{}}
               ], %{}},
              {"h2", [{"id", "actors"}], ["Actors"], %{}},
              {"p", [],
               [{"em", [], ["Libraries and tools for working with actors and such."], %{}}], %{}},
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
                    {"sub", [], ["20"], %{}},
                    "📅",
                    {"sub", [], ["20"], %{}},
                    " - Business Process Engine in Erlang. (",
                    {"a", [{"href", "https://bpe.n2o.dev"}], ["Doc"], %{}},
                    ")."
                  ], %{"days_off" => 20, "stars" => 20}}
               ], %{}},
              {"h2", [{"id", "algorithms-and-data-structures"}],
               ["Algorithms and Data structures"], %{}},
              {"p", [],
               [
                 {"em", [], ["Libraries and implementations of algorithms and data structures."],
                  %{}}
               ], %{}},
              {"ul", [],
               [
                 {"li", [],
                  [
                    {"a", [{"href", "https://github.com/sabiwara/aja"}], ["aja"], %{}},
                    "⭐",
                    {"sub", [], ["30"], %{}},
                    "📅",
                    {"sub", [], ["20"], %{}},
                    " - High performance persistent vectors and ordered maps."
                  ], %{"days_off" => 20, "stars" => 30}},
                 {"li", [],
                  [
                    {"a", [{"href", "https://github.com/takscape/elixir-array"}], ["array"], %{}},
                    "⭐",
                    {"sub", [], ["40"], %{}},
                    "📅",
                    {"sub", [], ["20"], %{}},
                    " - An Elixir wrapper library for Erlang's array."
                  ], %{"days_off" => 20, "stars" => 40}}
               ], %{}},
              {"h1", [{"id", "resources"}], ["Resources"], %{}},
              {"p", [],
               [
                 "Various resources, such as books, websites and articles, for improving your Elixir development skills and knowledge."
               ], %{}},
              {"h2", [{"id", "books"}], ["Books"], %{}},
              {"p", [], [{"em", [], ["Fantastic books and e-books."], %{}}], %{}}
            ]} == Awesome.Fetcher.get_data(%{})
  end

  test "result min stars 40" do
    _storage = :ets.new(:awesome_storage, [:set, :protected, :named_table])
    :ets.insert(:awesome_storage, {:awesome, @ast_struct})

    assert {:ok,
            [
              {"p", [],
               [
                 "There are ",
                 {"a", [{"href", "#other-awesome-lists"}],
                  ["other sites with curated lists of elixir packages"], %{}},
                 " which you can have a look at."
               ], %{}},
              {"ul", [],
               [
                 {"li", [],
                  [
                    {"a", [{"href", "#awesome-elixir"}], ["Awesome Elixir"], %{}},
                    {"ul", [],
                     [
                       {"li", [],
                        [
                          {"a", [{"href", "#algorithms-and-data-structures"}],
                           ["Algorithms and Data structures"], %{}}
                        ], %{}}
                     ], %{}}
                  ], %{}},
                 {"li", [],
                  [
                    {"a", [{"href", "#resources"}], ["Resources"], %{}},
                    {"ul", [], [{"li", [], [{"a", [{"href", "#books"}], ["Books"], %{}}], %{}}],
                     %{}}
                  ], %{}}
               ], %{}},
              {"h2", [{"id", "algorithms-and-data-structures"}],
               ["Algorithms and Data structures"], %{}},
              {"p", [],
               [
                 {"em", [], ["Libraries and implementations of algorithms and data structures."],
                  %{}}
               ], %{}},
              {"ul", [],
               [
                 {"li", [],
                  [
                    {"a", [{"href", "https://github.com/takscape/elixir-array"}], ["array"], %{}},
                    "⭐",
                    {"sub", [], ["40"], %{}},
                    "📅",
                    {"sub", [], ["20"], %{}},
                    " - An Elixir wrapper library for Erlang's array."
                  ], %{"days_off" => 20, "stars" => 40}}
               ], %{}},
              {"h1", [{"id", "resources"}], ["Resources"], %{}},
              {"p", [],
               [
                 "Various resources, such as books, websites and articles, for improving your Elixir development skills and knowledge."
               ], %{}},
              {"h2", [{"id", "books"}], ["Books"], %{}},
              {"p", [], [{"em", [], ["Fantastic books and e-books."], %{}}], %{}}
            ]} == Awesome.Fetcher.get_data(%{"min_stars" => "40"})
  end
end
