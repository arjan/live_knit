import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :live_knit, LiveKnitWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "41gecS9reNi4dVHBs3T+BHe98fm2uCGfZ3rb2aZW+1/JpOpleyabQu3pa9iAItev",
  server: false

config :live_knit, LiveKnit.Repo,
  database: "test.db",
  pool: Ecto.Adapters.SQL.Sandbox

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
