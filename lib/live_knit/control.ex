defmodule LiveKnit.Control do
  use GenServer
  use LiveKnit.Broadcaster, "control"

  require Logger

  alias LiveKnit.{Serial, Machine, Settings}

  defstruct machine: nil,
            single_color: false,
            knitting: false,
            pattern_settings: %Settings{},
            machine_settings: %Settings{},
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

  def set_single_color(flag) do
    GenServer.call(__MODULE__, {:set_single_color, flag})
  end

  def change_settings(attrs) do
    GenServer.call(__MODULE__, {:change_settings, attrs})
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    LiveKnit.Serial.subscribe()

    settings = %Settings{width: 16, image: ["10", "01"], repeat_x: true, repeat_y: true}
    {:ok, apply_pattern_settings(%State{}, settings)}
  end

  def handle_call(:status, _from, state) do
    {:reply, get_status(state), state}
  end

  def handle_call(:reset, _from, state) do
    {:reply, :ok, reset(state)}
  end

  def handle_call({:set_knitting, flag}, _from, state) do
    {:reply, :ok, %State{state | knitting: flag} |> send_state()}
  end

  def handle_call({:set_single_color, flag}, _from, state) do
    state =
      case flag do
        true ->
          settings = %{
            state.machine_settings
            | colors: 1,
              image: ["0"],
              repeat_x: true,
              repeat_y: true
          }

          Machine.load(%Machine.Passap{}, settings)
          |> handle_machine_response(%State{
            state
            | single_color: true,
              machine_settings: settings
          })

        false ->
          apply_pattern_settings(state, state.pattern_settings)
      end

    {:reply, :ok, state |> send_state()}
  end

  def handle_call({:change_settings, attrs}, _from, state) do
    case Settings.apply(state.pattern_settings, attrs) do
      {:ok, settings} ->
        state = apply_pattern_settings(state, settings)

        {:reply, :ok, state}

      {:error, message} ->
        {:reply, {:error, message}, state}
    end
  end

  def handle_info({:serial_out, _data}, state) do
    {:noreply, state}
  end

  def handle_info({:serial_in, data}, %State{knitting: true} = state) do
    state =
      Machine.interpret_serial(state.machine, data)
      |> handle_machine_response(state)

    {:noreply, state}
  end

  def handle_info({:serial_in, _data}, state) do
    {:noreply, state}
  end

  def handle_info(message, state) do
    Logger.warn("#{inspect(message)}")

    {:noreply, state}
  end

  defp reset(state) do
    Machine.load(%Machine.Passap{}, state.machine_settings)
    |> handle_machine_response(%State{state | knitting: false, history: []})
    |> send_state()
  end

  defp apply_pattern_settings(state, settings) do
    Machine.load(%Machine.Passap{}, settings)
    |> handle_machine_response(%State{
      state
      | pattern_settings: settings,
        machine_settings: settings,
        single_color: false
    })
  end

  defp handle_machine_response({instructions, :done}, state) do
    Enum.reduce(instructions, state, &handle_instruction/2)
    |> reset()
  end

  defp handle_machine_response({instructions, machine}, state) do
    Enum.reduce(instructions, %State{state | machine: machine}, &handle_instruction/2)
    |> send_state()
  end

  defp handle_instruction({:write, data}, state) do
    Logger.debug("WRITE --> #{data}")
    Serial.write(data)
    state
  end

  defp handle_instruction({:write_delayed, data, time}, state) do
    Logger.debug("WRITE --> #{data} (after #{time}ms)")

    Task.start(fn ->
      Process.sleep(time)
      Serial.write(data)
    end)

    state
  end

  defp handle_instruction({:status, status}, state) do
    # Logger.debug("STATUS = #{inspect(status)}")
    %State{state | machine_status: status}
  end

  defp handle_instruction({:row, row}, state) do
    %State{state | history: [row | state.history]}
  end

  defp get_status(state) do
    Map.take(state, ~w(knitting single_color machine_status history)a)
    |> Map.put(:upcoming, Machine.peek(state.machine, 40))
    |> Map.put(
      :settings,
      case state.single_color do
        true -> state.machine_settings
        false -> state.pattern_settings
      end
    )
  end

  defp send_state(state) do
    broadcast({:status, get_status(state)})

    state
  end
end
