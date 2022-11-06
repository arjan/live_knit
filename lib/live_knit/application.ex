defmodule LiveKnit.Application do
  @moduledoc false
  require Logger

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        # Start the Telemetry supervisor
        LiveKnitWeb.Telemetry,
        # Start the PubSub system
        {Phoenix.PubSub, name: LiveKnit.PubSub},
        # Start the Endpoint (http/https)
        LiveKnitWeb.Endpoint,
        # The serial connection
        LiveKnit.SerialManager,
        # Knitting controller
        LiveKnit.Control
      ]
      |> List.flatten()

    opts = [strategy: :one_for_one, name: LiveKnit.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LiveKnitWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
