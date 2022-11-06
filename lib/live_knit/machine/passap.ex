defmodule LiveKnit.Machine.Passap do
  defstruct cursor: 0,
            direction: :uncalibrated,
            current_pattern: "",
            rows: [],
            data: [],
            repeat: false,
            first_needle: 0

  @bed_width 180

  def cursor_to_needle(c) do
    div(@bed_width - c, 2)
  end
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
    bw2 = div(@bed_width, 2)
    first_needle = ceil(bw2 - settings.width / 2) - settings.center
    first_needle = max(0, first_needle)
    first_needle = min(@bed_width - settings.width, first_needle)

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

  def knit(%State{direction: {:new_row, _}, rows: [], repeat: false} = _state) do
    :done
  end

  def knit(%State{direction: {:new_row, _}, rows: [], repeat: true} = state) do
    knit(%State{state | rows: state.data})
  end

  def knit(%State{direction: {:new_row, _}} = state) do
    [current_pattern | rest] = state.rows

    state = %State{
      state
      | direction: {:ltr, 0},
        rows: rest,
        current_pattern: current_pattern
    }

    instructions = [
      {:write, "F:#{state.first_needle}"},
      {:write, "P:" <> current_pattern},
      state_instruction(state),
      {:row, current_pattern}
    ]

    {instructions, state}
  end

  def knit(%State{direction: {:ltr, 0}} = state) do
    state = %State{state | direction: {:rtl, 1}}

    instructions = [state_instruction(state)]
    {instructions, state}
  end

  def knit(%State{direction: {:rtl, 1}} = state) do
    pattern = Pattern.invert_row(state.current_pattern)
    state = %State{state | direction: {:ltr, 1}}

    instructions = [{:write, "P:" <> pattern}, state_instruction(state)]

    {instructions, state}
  end

  def knit(%State{direction: {:ltr, 1}} = state) do
    state = %State{state | direction: {:new_row, 1}}
    instructions = [state_instruction(state)]
    {instructions, state}
  end

  defp state_instruction(state) do
    center = div(@bed_width, 2)
    right_needle = @bed_width - state.first_needle - center
    left_needle = right_needle - String.length(List.first(state.data) || "")
    position = @bed_width - div(state.cursor + 2, 2) - center

    {direction, color} = color_and_direction(state.direction)

    {:status,
     %{
       direction: direction,
       color: color,
       position: position,
       left_needle: left_needle,
       right_needle: right_needle
     }}
  end

  # state.direction always contains the 'next direction' instead of the current
  defp color_and_direction({:rtl, col}), do: {:ltr, 1 - col}
  defp color_and_direction({:ltr, col}), do: {:rtl, col}
  defp color_and_direction({:new_row, col}), do: {:ltr, col}
  defp color_and_direction(d), do: {d, 0}

  @impl true
  def interpret_serial(machine, "R:fc") do
    calibrated(machine)
  end

  def interpret_serial(machine, "E:1") do
    knit(machine)
  end

  def interpret_serial(machine, "C:" <> n) do
    case Integer.parse(n) do
      {cursor, _} ->
        machine = %State{machine | cursor: cursor}
        {[state_instruction(machine)], machine}

      :error ->
        {[], machine}
    end
  end

  def interpret_serial(machine, _data) do
    {[], machine}
  end

  @impl true
  def peek(%{repeat: true} = machine, n) do
    repeats = ceil(n / max(1, Enum.count(machine.data)))

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
    knit(%State{machine | direction: {:new_row, 0}})
  end

  def calibrated(machine) do
    {[], machine}
  end
end
