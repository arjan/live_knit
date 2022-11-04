defmodule LiveKnit.Control do
  use GenServer

  require Logger

  alias LiveKnit.{Serial, Machine, Settings}

  @topic "control"
  def topic(), do: @topic

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

  def reset() do
    GenServer.call(__MODULE__, :reset)
  end

  def set_knitting(flag) do
    GenServer.call(__MODULE__, {:set_knitting, flag})
  end

  def change_settings(attrs) do
    GenServer.call(__MODULE__, {:change_settings, attrs})
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

  def handle_call(:reset, _from, state) do
    {:reply, :ok, reset(state) |> broadcast()}
  end

  def handle_call({:set_knitting, flag}, _from, state) do
    {:reply, :ok, %State{state | knitting: flag} |> broadcast()}
  end

  def handle_call({:change_settings, attrs}, _from, state) do
    case Settings.apply(state.settings, attrs) do
      {:ok, settings} ->
        machine = Machine.load(%Machine.Passap{}, settings)
        {:reply, :ok, %State{settings: settings, machine: machine} |> broadcast()}

      {:error, message} ->
        {:reply, {:error, message}, state}
    end
  end

  def handle_info({:serial_out, _data}, state) do
    {:noreply, state}
  end

  def handle_info({:serial_in, data}, state) do
    IO.inspect(data, label: "data")

    state =
      case Machine.interpret_serial(state.machine, data) do
        :calibration_done ->
          if state.knitting and state.machine_status == %{} do
            knit(state)
          else
            state
          end

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

        reset(state)

      {instructions, machine} ->
        Enum.reduce(instructions, %State{state | machine: machine}, &handle_instruction/2)
    end
    |> broadcast()
  end

  defp reset(state) do
    %State{
      state
      | knitting: false,
        machine: Machine.reset(state.machine),
        history: [],
        machine_status: %{}
    }
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
    |> Map.put(:upcoming, Machine.peek(state.machine, 40))
  end

  defp broadcast(state) do
    Phoenix.PubSub.broadcast(LiveKnit.PubSub, @topic, {:status, get_status(state)})

    state
  end
end
