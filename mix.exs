defmodule LiveKnit.MixProject do
  use Mix.Project

  def project do
    [
      app: :live_knit,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {LiveKnit.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nerves_uart, "~> 1.2"},
      {:phoenix_pubsub, "~> 2.0"},
      {:pixels, "~> 0.0"}
    ]
  end
end
