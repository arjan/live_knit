# General application configuration
import Config

config :live_knit,
  ecto_repos: [LiveKnit.Repo]

config :live_knit, LiveKnit.Repo, database: "#{__DIR__}/../database.db"

# Configures the endpoint
config :live_knit, LiveKnitWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: LiveKnitWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: LiveKnit.PubSub,
  live_view: [signing_salt: "+5T7Fr9Y"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.29",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
