defmodule LiveKnit.SerialManager do
  use GenServer
  use LiveKnit.Broadcaster, "serial_manager"

  require Logger

  alias LiveKnit.{Serial, SerialStub}

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def status() do
    GenServer.call(__MODULE__, :status)
  end

  ###

  defstruct serial_pid: nil, stub_pid: nil, connected: false, port: ""
  alias __MODULE__, as: State

  def init(_) do
    Process.flag(:trap_exit, true)
    :timer.send_interval(1000, :poll)
    {:ok, %State{}, {:continue, :check}}
  end

  def handle_continue(:check, state) do
    {:noreply, poll(state)}
  end

  def handle_call(:status, _from, state) do
    {:reply, status(state), state}
  end

  def handle_info(:poll, state) do
    {:noreply, poll(state)}
  end

  def handle_info({:EXIT, serial_pid, _}, %State{serial_pid: serial_pid} = state) do
    {:noreply, %State{state | serial_pid: nil}}
  end

  def handle_info({:EXIT, stub_pid, _}, %State{stub_pid: stub_pid} = state) do
    {:noreply, %State{state | stub_pid: nil}}
  end

  def handle_info(_message, state) do
    {:noreply, state}
  end

  defp poll(%State{serial_pid: nil} = state) do
    case find_arduino() do
      nil ->
        case state.stub_pid do
          nil ->
            Logger.warn("Serial port not found, using stub serial")
            {:ok, stub_pid} = SerialStub.start_link()
            %State{state | connected: false, stub_pid: stub_pid} |> send_state()

          _pid ->
            state
        end

      {port, _metadata} ->
        Logger.warn("Found Arduino at #{port}")
        Process.sleep(1000)

        if state.stub_pid != nil do
          GenServer.stop(state.stub_pid)
        end

        {:ok, serial_pid} = Serial.start_link(port)

        %State{state | connected: true, port: port, serial_pid: serial_pid}
        |> send_state()
    end
  end

  defp poll(state), do: state

  defp find_arduino() do
    Nerves.UART.enumerate()
    |> Enum.find(fn {_k, v} ->
      String.starts_with?(Map.get(v, :manufacturer, ""), "Arduino")
    end)
  end

  defp status(state), do: Map.take(state, [:port, :connected])

  defp send_state(state) do
    broadcast({:serial_status, status(state)})

    state
  end
end
