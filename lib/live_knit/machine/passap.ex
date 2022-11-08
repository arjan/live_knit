defmodule LiveKnit.Machine.Passap do
  defstruct direction: :uncalibrated,
            current_pattern: "",
            rows_remaining: 0,
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
        first_needle: first_needle,
        rows_remaining:
          case settings.repeat_y do
            true -> settings.repeat_y_count
            false -> Enum.count(rows)
          end
    }

    {[state_instruction(machine)], machine}
  end

  @impl true
  def knit(%State{direction: :uncalibrated} = state) do
    {[], state}
  end

  def knit(%State{direction: {:new_row, _}, rows_remaining: 0} = _state) do
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
        current_pattern: current_pattern,
        rows_remaining: state.rows_remaining - 1
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

    {direction, color, rows_remaining} =
      color_and_direction(state.direction, state.rows_remaining)

    {:status,
     %{
       direction: direction,
       color: color,
       left_needle: left_needle,
       right_needle: right_needle,
       rows_remaining: rows_remaining
     }}
  end

  # state.direction always contains the 'next direction' instead of the current
  defp color_and_direction({:rtl, col}, r), do: {:ltr, 1 - col, r + 1}
  defp color_and_direction({:ltr, col}, r), do: {:rtl, col, r + 1}
  defp color_and_direction({:new_row, col}, r), do: {:ltr, col, r}
  defp color_and_direction(d, r), do: {d, 0, r}

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
    n = min(n, machine.rows_remaining)
    repeats = ceil(n / max(1, Enum.count(machine.data))) + 1

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
      first_needle: machine.first_needle,
      rows_remaining: Enum.count(machine.data)
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
