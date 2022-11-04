defmodule LiveKnit.Application do
  @moduledoc false
  require Logger

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        {Phoenix.PubSub, name: LiveKnit.PubSub},
        serial_port(),
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
      String.starts_with?(Map.get(v, :manufacturer), "Arduino")
    end)
  end
end
