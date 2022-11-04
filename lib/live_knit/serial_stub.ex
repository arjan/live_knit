defmodule LiveKnit.SerialStub do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: LiveKnit.Serial)
  end

  def init(_) do
    {:ok, nil}
  end

  def handle_cast({:write, data}, state) do
    Phoenix.PubSub.broadcast(LiveKnit.PubSub, LiveKnit.Serial.topic(), {:serial_out, data})
    {:noreply, state}
  end
end
