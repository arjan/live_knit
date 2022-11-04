defmodule LiveKnit.Machine.Passap do
  defstruct color: 0,
            direction: :rtl,
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

    %State{state | rows: rows, data: rows, repeat: settings.repeat_y, first_needle: first_needle}
  end

  @impl true
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
    {:status, %{direction: state.direction, color: state.color}}
  end

  @impl true
  def interpret_serial(_machine, "R:fc"), do: :calibration_done
  def interpret_serial(_machine, "E:1"), do: :knit_row
  def interpret_serial(_machine, _data), do: :ignore

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
    %State{
      rows: machine.data,
      data: machine.data,
      repeat: machine.repeat,
      first_needle: machine.first_needle
    }
  end
end
