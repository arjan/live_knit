defmodule LiveKnit.Machine.Passap do
  defstruct color: 0, direction: :rtl, rows: [], data: [], current_pattern: "", repeat: false
end

defimpl LiveKnit.Machine, for: LiveKnit.Machine.Passap do
  alias LiveKnit.Machine.Passap, as: State
  alias LiveKnit.Pattern
  alias LiveKnit.Settings

  def load(state, settings) do
    rows = Settings.to_pattern(settings)
    %State{state | rows: rows, data: rows, repeat: settings.repeat_y}
  end

  def knit(%State{direction: :rtl, color: 0, rows: [], repeat: false} = _state) do
    :done
  end

  def knit(%State{direction: :rtl, color: 0, rows: [], repeat: true} = state) do
    knit(%State{state | rows: state.data})
  end

  def knit(%State{direction: :rtl, color: 0} = state) do
    [current_pattern | rest] = state.rows
    instructions = [{:write, "P:" <> current_pattern}, state_instruction(state)]

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
end
