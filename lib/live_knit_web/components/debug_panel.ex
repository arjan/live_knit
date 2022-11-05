defmodule LiveKnitWeb.Components.DebugPanel do
  use LiveKnitWeb, :live_component

  def mount(socket) do
    socket = socket |> assign(:debug, false)
    {:ok, socket}
  end

  def handle_event("form-change", %{"cursor" => value}, socket) do
    LiveKnit.SerialStub.read("C:" <> value)
    {:noreply, socket}
  end

  def handle_event("form-change", _attrs, socket) do
    {:noreply, socket}
  end

  def handle_event("toggle-debug", attrs, socket) do
    socket = assign(socket, :debug, attrs["value"] == "on")
    {:noreply, socket}
  end

  def handle_event("calibrate", _, socket) do
    LiveKnit.SerialStub.read("R:fc")
    {:noreply, socket}
  end

  def handle_event("pattern_end", _, socket) do
    LiveKnit.SerialStub.read("E:1")
    {:noreply, socket}
  end

  defdelegate cursor_to_needle(c), to: LiveKnit.Machine.Passap
end
