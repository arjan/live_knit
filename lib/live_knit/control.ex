defmodule LiveKnit.Control do
  use GenServer

  require Logger

  alias LiveKnit.{Serial, Machine}

  defstruct machine: nil
  alias __MODULE__, as: State

  def reset() do
    GenServer.cast(__MODULE__, :reset)
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    Phoenix.PubSub.subscribe(LiveKnit.PubSub, Serial.topic())

    {:ok, %State{}}
  end

  def handle_cast(:reset, %State{} = state) do
    Serial.write("F:20")

    machine =
      Machine.load(%Machine.Passap{repeat: false}, [
        "1111111111111111",
        "1111111111111111",
        "1111111111111111",
        "1111111111111111"
      ])

    {:noreply, %State{state | machine: machine} |> knit()}
  end

  def handle_info({:serial, "R:fc"}, %State{machine: nil} = state) do
    Serial.write("F:20")

    machine = Machine.load(%Machine.Passap{repeat: true}, ["1100110011001100"])
    {:noreply, %State{state | machine: machine} |> knit()}
  end

  def handle_info({:serial, "E:1"}, %State{} = state) do
    {:noreply, knit(state)}
  end

  def handle_info({:serial, data}, %State{} = state) do
    Logger.debug("READ  <-- #{data}")
    {:noreply, state}
  end

  def handle_info(message, state) do
    Logger.warn("#{inspect(message)}")

    {:noreply, state}
  end

  defp knit(%State{machine: nil} = state) do
    # ignore
    state
  end

  defp knit(state) do
    case Machine.knit(state.machine) do
      :done ->
        Logger.warn("- machine done -")

        %State{state | machine: nil}

      {instructions, machine} ->
        Enum.each(instructions, &handle_instruction/1)
        %State{state | machine: machine}
    end
  end

  defp handle_instruction({:write, data}) do
    Logger.debug("WRITE --> #{data}")
    Serial.write(data)
  end

  defp handle_instruction({:status, status}) do
    Logger.debug("STATUS = #{inspect(status)}")
  end
end
