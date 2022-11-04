defprotocol LiveKnit.Machine do
  alias LiveKnit.Pattern

  @type t :: term()

  @type instruction :: {:write, binary()} | {:status, %{direction: :ltr | :rtl, color: 0 | 1}}

  @callback load(t(), [Pattern.row()]) :: t()
  def load(machine, rows)

  @callback knit(t()) :: {[instruction()], t()} | :done
  def knit(machine)
end
