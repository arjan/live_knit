defmodule LiveKnit.Serial do
  use GenServer

  require Logger

  def start_link(port) do
    GenServer.start_link(__MODULE__, port, name: __MODULE__)
  end

  @topic "serial_data"
  def topic(), do: @topic

  def write(data) do
    GenServer.cast(__MODULE__, {:write, data})
  end

  ### internal

  defstruct pid: nil, port: nil
  alias __MODULE__, as: State

  def init(port) do
    {:ok, pid} = Nerves.UART.start_link()
    Logger.warn("#{port}")

    :ok = Nerves.UART.open(pid, port, speed: 115_200, active: true)

    Nerves.UART.configure(pid,
      framing: {Nerves.UART.Framing.Line, separator: "\n"},
      rx_framing_timeout: 1000
    )

    {:ok, %State{pid: pid, port: port}}
  end

  def handle_cast({:write, data}, state) do
    Nerves.UART.write(state.pid, data <> "\n\n")
    Nerves.UART.drain(state.pid)

    {:noreply, state}
  end

  def handle_info({:nerves_uart, port, data}, %State{port: port} = state) do
    Phoenix.PubSub.broadcast(LiveKnit.PubSub, @topic, {:serial, data})

    {:noreply, state}
  end

  def handle_info(message, state) do
    Logger.warn("message #{inspect(message)}")

    {:noreply, state}
  end
end
