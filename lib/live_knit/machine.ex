defprotocol LiveKnit.Machine do
  alias LiveKnit.Settings

  @type t :: term()

  @type instruction :: {:write, binary()} | {:status, %{direction: :ltr | :rtl, color: 0 | 1}}

  @callback load(t(), Settings.t()) :: t()
  def load(machine, settings)

  @callback knit(t()) :: {[instruction()], t()} | :done
  def knit(machine)
end
