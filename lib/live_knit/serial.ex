defmodule LiveKnit.Serial do
  use GenServer
  use LiveKnit.Broadcaster, "serial_data"

  require Logger

  def start_link(port) do
    GenServer.start_link(__MODULE__, port, name: __MODULE__)
  end

  def write(data) do
    GenServer.cast(__MODULE__, {:write, data})
  end

  ### internal

  defstruct pid: nil, port: nil
  alias __MODULE__, as: State

  def init(port) do
    {:ok, pid} = Nerves.UART.start_link()
    Logger.warn("#{port}")

    case Nerves.UART.open(pid, port, speed: 115_200, active: true) do
      :ok ->
        Nerves.UART.configure(pid,
          framing: {Nerves.UART.Framing.Line, separator: "\n"},
          rx_framing_timeout: 100
        )

        {:ok, %State{pid: pid, port: port}}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  def handle_cast({:write, data}, state) do
    broadcast({:serial_out, data})

    Nerves.UART.write(state.pid, data <> "\n\n")
    Nerves.UART.drain(state.pid)

    {:noreply, state}
  end

  def handle_info({:nerves_uart, port, {:error, reason}}, %State{port: port} = state) do
    Logger.error("Serial error: #{inspect(reason)}")

    {:stop, :normal, state}
  end

  def handle_info({:nerves_uart, port, data}, %State{port: port} = state) do
    broadcast({:serial_in, data})

    {:noreply, state}
  end

  def handle_info(message, state) do
    Logger.warn("message #{inspect(message)}")

    {:noreply, state}
  end
end
