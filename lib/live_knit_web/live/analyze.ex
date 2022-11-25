defmodule LiveKnitWeb.Live.Analyze do
  use LiveKnitWeb, :live_view

  alias LiveKnit.{Serial, SerialManager}

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    if connected?(socket) do
      #      :timer.send_interval(50, self(), :chart_test)
      Serial.subscribe()
      SerialManager.subscribe()
    end

    socket =
      socket
      |> assign(:serial_status, SerialManager.status())

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_info(:chart_test, socket) do
    socket = push_event(socket, "datapoint", %{value: [r(), r()]})
    {:noreply, socket}
  end

  def handle_info({:serial_in, "S:" <> data}, socket) do
    value = data |> String.split(" ") |> Enum.map(&String.to_integer/1)
    socket = push_event(socket, "datapoint", %{value: value})
    {:noreply, socket}
  end

  def handle_info({:serial_in, _}, socket) do
    {:noreply, socket}
  end

  def handle_info({:serial_status, status}, socket) do
    {:noreply, socket |> assign(:serial_status, status)}
  end

  defp r(), do: Enum.random([0, 1])
end
