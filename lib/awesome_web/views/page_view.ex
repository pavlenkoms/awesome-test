defmodule AwesomeWeb.PageView do
  use AwesomeWeb, :view

  def as_html(txt) do
    txt |> raw()
  end

  def days_off(project) do
    Kernel.trunc(project["seconds_off"] / 60 / 60 / 24)
  end

  def to_sort_list(some) do
    some
    |> Map.keys()
    |> Enum.sort()
    |> Enum.map(fn name ->
      some[name]
    end)
  end
end
