defmodule Awesome.Fetcher.PersistCache do
  def create(cache_file) do
    :dets.open_file(cache_file, file: cache_file, ram_file: true)
  end

  def close(cache) do
    :dets.sync(cache)
    :dets.close(cache)
  end

  def put(cache, key, data) do
    :dets.insert(cache, {key, data, :used})
  end

  def get(cache, key) do
    case :dets.lookup(cache, key) do
      [{key, value, _}] -> {key, value}
      [] -> {key, nil}
    end
  end

  def touch(cache, key) do
    case :dets.lookup(cache, key) do
      [{key, value, _}] -> :dets.insert(cache, {key, value, :used})
      [] -> nil
    end

    :ok
  end

  def collect_garbage(cache) do
    :dets.select_delete(cache, [
      {{:_, :_, :"$1"}, [{:==, :"$1", :not_used}], [true]}
    ])

    elements = :dets.foldl(fn el, acc -> [el | acc] end, [], cache)

    Enum.each(elements, fn el ->
      {key, value, _} = el
      :dets.insert(cache, {key, value, :not_used})
    end)

    :ok
  end
end
