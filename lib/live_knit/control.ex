defmodule LiveKnit.Control do
  use GenServer

  require Logger

  alias LiveKnit.{Serial, Machine, Settings}

  defstruct machine: nil,
            knitting: false,
            calibrated: false,
            settings: %Settings{},
            machine_status: %{},
            history: []

  alias __MODULE__, as: State

  def status() do
    GenServer.call(__MODULE__, :status)
  end

  def set_knitting(flag) do
    GenServer.call(__MODULE__, {:set_knitting, flag})
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    Phoenix.PubSub.subscribe(LiveKnit.PubSub, Serial.topic())

    settings = %Settings{width: 16, image: ["10", "01"], repeat_x: true, repeat_y: true}

    machine = Machine.load(%Machine.Passap{}, settings)
    {:ok, %State{settings: settings, machine: machine}}
  end

  def handle_call(:status, _from, state) do
    {:reply, get_status(state), state}
  end

  def handle_call({:set_knitting, flag}, _from, state) do
    {:reply, :ok, %State{state | knitting: flag}}
  end

  def handle_info({:serial_out, _data}, state) do
    {:noreply, state}
  end

  def handle_info({:serial_in, data}, state) do
    state =
      case Machine.interpret_serial(state.machine, data) do
        :knit_row ->
          if state.knitting do
            knit(state)
          else
            state
          end

        :ignore ->
          state
      end

    {:noreply, state}
  end

  def handle_info(:knit, state) do
    {:noreply, knit(state)}
  end

  def handle_info(message, state) do
    Logger.warn("#{inspect(message)}")

    {:noreply, state}
  end

  defp knit(state) do
    case Machine.knit(state.machine) do
      :done ->
        Logger.warn("- machine done -")

        %State{state | knitting: false, machine: Machine.reset(state.machine)}

      {instructions, machine} ->
        Enum.reduce(instructions, %State{state | machine: machine}, &handle_instruction/2)
    end
  end

  defp handle_instruction({:write, data}, state) do
    Logger.debug("WRITE --> #{data}")
    Serial.write(data)
    state
  end

  defp handle_instruction({:status, status}, state) do
    Logger.debug("STATUS = #{inspect(status)}")
    %State{state | machine_status: status}
  end

  defp handle_instruction({:row, row}, state) do
    %State{state | history: [row | state.history]}
  end

  defp get_status(state) do
    Map.take(state, ~w(knitting calibrated machine_status history settings)a)
    |> Map.put(:upcoming, Machine.peek(state.machine, 20))
  end
end
