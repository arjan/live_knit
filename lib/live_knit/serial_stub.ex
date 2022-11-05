defmodule LiveKnit.SerialStub do
  use GenServer

  alias LiveKnit.{PubSub, Serial}

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: Serial)
  end

  def read(data) do
    Phoenix.PubSub.broadcast(PubSub, Serial.topic(), {:serial_in, data})
  end

  def init(_) do
    {:ok, nil}
  end

  def handle_cast({:write, data}, state) do
    Phoenix.PubSub.broadcast(PubSub, Serial.topic(), {:serial_out, data})
    {:noreply, state}
  end
end
