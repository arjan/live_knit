defmodule LiveKnit.SerialStub do
  use GenServer

  alias LiveKnit.Serial

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: Serial)
  end

  def read(data) do
    Serial.broadcast({:serial_in, data})
  end

  def init(_) do
    {:ok, nil}
  end

  def handle_cast({:write, data}, state) do
    Serial.broadcast({:serial_out, data})
    {:noreply, state}
  end
end
