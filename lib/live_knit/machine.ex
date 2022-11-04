defprotocol LiveKnit.Machine do
  alias LiveKnit.{Pattern, Settings}

  @type t :: term()

  @type instruction ::
          {:write, binary()}
          | {:status, %{direction: :ltr | :rtl, color: 0 | 1}}
          | {:row, Pattern.row()}

  @callback load(t(), Settings.t()) :: t()
  def load(machine, settings)

  @callback knit(t()) :: {[instruction()], t()} | :done
  def knit(machine)

  @callback interpret_serial(t(), binary()) :: :knit_row | :calibration_done | :ignore
  def interpret_serial(machine, data)

  @callback peek(t(), non_neg_integer()) :: [Pattern.row()]
  def peek(machine, n)

  @callback reset(t()) :: t()
  def reset(machine)
end
