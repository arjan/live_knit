defmodule LiveKnitWeb.Live.Analyze do
  use LiveKnitWeb, :live_view

  alias LiveKnit.{Serial, SerialManager}

  defp rt(), do: Enum.random(0..50) + 20

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    if connected?(socket) do
      #      :timer.send_interval(50, self(), :chart_test)
      #      Process.send_after(self(), :chart_test, rt())
      Serial.subscribe()
      SerialManager.subscribe()
    end

    socket =
      socket
      |> assign(:serial_status, SerialManager.status())
      |> assign(:direction, "?")
      |> assign(:cursor, "?")

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_info(:chart_test, socket) do
    time = :erlang.convert_time_unit(:erlang.monotonic_time(), :native, :microsecond)
    Process.send_after(self(), :chart_test, rt())

    socket = push_event(socket, "datapoint", %{time: time, value: [r(), r()]})
    {:noreply, socket}
  end

  def handle_info({:serial_in, "D:" <> data}, socket) do
    {:noreply, socket |> assign(:direction, data)}
  end

  def handle_info({:serial_in, "C:" <> data}, socket) do
    {:noreply, socket |> assign(:cursor, data)}
  end

  def handle_info({:serial_in, "S:" <> data}, socket) do
    [time | values] = data |> String.trim() |> String.split(" ") |> Enum.map(&String.to_integer/1)

    socket = push_event(socket, "datapoint", %{time: time, value: values})
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
