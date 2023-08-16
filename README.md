# Awesome

Перед запуском положите токен от гитхаба в конфиг

```elixir

config :awesome, Awesome.Fetcher.Github.HttpClient,
  token: "SOME_TOKEN"

end
```

для запуска Awesome:

  * Стяните зависимости `mix deps.get`
  * Установите ноджс потроха `cd assets && npm install`
  * Запустите `mix phx.server`

Теперь можно найти страничку на [`localhost:4000`](http://localhost:4000).
