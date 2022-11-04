defprotocol LiveKnit.Machine do
  alias LiveKnit.{Pattern, Settings}

  @type t :: term()

  @type instruction ::
          {:write, binary()}
          | {:status, %{direction: :ltr | :rtl, color: 0 | 1}}
          | {:row, Pattern.row()}

  @callback load(t(), Settings.t()) :: {[instruction()], t()}
  def load(machine, settings)

  @callback interpret_serial(t(), binary()) :: {[instruction()], t()}
  def interpret_serial(machine, data)

  @callback peek(t(), non_neg_integer()) :: [Pattern.row()]
  def peek(machine, n)

  @callback reset(t()) :: {[instruction()], t()}
  def reset(machine)

  @callback knit(t()) :: {[instruction()], t()}
  def knit(machine)

  @callback calibrated(t()) :: {[instruction()], t()}
  def calibrated(machine)
end
