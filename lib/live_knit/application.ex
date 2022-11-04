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
        serial_port(),
        # Knitting controller
        LiveKnit.Control
      ]
      |> List.flatten()

    opts = [strategy: :one_for_one, name: LiveKnit.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @testing Mix.env() == :test

  defp serial_port() do
    case find_arduino() do
      {port, _metadata} ->
        {LiveKnit.Serial, port}

      nil ->
        unless @testing do
          Logger.warn("Serial port not found, using stub!")
        end

        LiveKnit.SerialStub
    end
  end

  defp find_arduino() do
    Nerves.UART.enumerate()
    |> Enum.find(fn {_k, v} ->
      String.starts_with?(Map.get(v, :manufacturer, ""), "Arduino")
    end)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LiveKnitWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
