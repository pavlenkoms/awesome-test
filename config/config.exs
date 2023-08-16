# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Configures the endpoint
config :awesome, AwesomeWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "ppJiowgbUP120QxXWgDw6PxtV3ElqG8rKToTd2p+awQRlwEQwiV62XfAUmPfAoiW",
  render_errors: [view: AwesomeWeb.ErrorView, accepts: ~w(html json)]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  level: :info

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :awesome, Awesome.Fetcher.Github.HttpClient, token: nil

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
