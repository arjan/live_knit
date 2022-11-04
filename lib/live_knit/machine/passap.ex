defmodule LiveKnit.Machine.Passap do
  defstruct color: 0,
            direction: :uncalibrated,
            current_pattern: "",
            rows: [],
            data: [],
            repeat: false,
            first_needle: 0
end

defimpl LiveKnit.Machine, for: LiveKnit.Machine.Passap do
  alias LiveKnit.Machine.Passap, as: State
  alias LiveKnit.Pattern
  alias LiveKnit.Settings

  @bed_width 180

  @impl true
  def load(state, settings) do
    rows = Settings.to_pattern(settings)

    # center the work on the bed
    first_needle = ceil(@bed_width / 2 + settings.width / 2)

    machine = %State{
      state
      | direction: :uncalibrated,
        rows: rows,
        data: rows,
        repeat: settings.repeat_y,
        first_needle: first_needle
    }

    {[state_instruction(machine)], machine}
  end

  @impl true
  def knit(%State{direction: :uncalibrated} = state) do
    {[], state}
  end

  def knit(%State{direction: :rtl, color: 0, rows: [], repeat: false} = _state) do
    :done
  end

  def knit(%State{direction: :rtl, color: 0, rows: [], repeat: true} = state) do
    knit(%State{state | rows: state.data})
  end

  def knit(%State{direction: :rtl, color: 0} = state) do
    [current_pattern | rest] = state.rows

    instructions = [
      {:write, "F:#{state.first_needle}"},
      {:write, "P:" <> current_pattern},
      state_instruction(state),
      {:row, current_pattern}
    ]

    {instructions, %State{state | direction: :ltr, rows: rest, current_pattern: current_pattern}}
  end

  def knit(%State{direction: :ltr, color: 0} = state) do
    instructions = [state_instruction(state)]
    {instructions, %State{state | direction: :rtl, color: 1}}
  end

  def knit(%State{direction: :rtl, color: 1} = state) do
    pattern = Pattern.invert_row(state.current_pattern)
    instructions = [{:write, "P:" <> pattern}, state_instruction(state)]

    {instructions, %State{state | direction: :ltr}}
  end

  def knit(%State{direction: :ltr, color: 1} = state) do
    instructions = [state_instruction(state)]
    {instructions, %State{state | direction: :rtl, color: 0}}
  end

  defp state_instruction(state) do
    center = div(@bed_width, 2)
    left_needle = state.first_needle - String.length(List.first(state.data)) - center
    right_needle = state.first_needle - center

    {:status,
     %{
       direction: state.direction,
       color: state.color,
       left_needle: left_needle,
       right_needle: right_needle
     }}
  end

  @impl true
  def interpret_serial(machine, "R:fc") do
    calibrated(machine)
  end

  def interpret_serial(machine, "E:1") do
    knit(machine)
  end

  def interpret_serial(machine, _data) do
    {[], machine}
  end

  @impl true
  def peek(%{repeat: true} = machine, n) do
    repeats = ceil(n / Enum.count(machine.data))

    [
      machine.rows,
      for _ <- 1..repeats do
        machine.data
      end
    ]
    |> List.flatten()
    |> Enum.slice(0, n)
  end

  def peek(%{repeat: false} = machine, _n) do
    machine.rows
  end

  @impl true
  def reset(machine) do
    state = %State{
      rows: machine.data,
      data: machine.data,
      repeat: machine.repeat,
      first_needle: machine.first_needle
    }

    {[state_instruction(state)], state}
  end

  @impl true

  def calibrated(%State{direction: :uncalibrated} = machine) do
    knit(%State{machine | direction: :rtl, color: 0})
  end

  def calibrated(machine) do
    {[], machine}
  end
end
