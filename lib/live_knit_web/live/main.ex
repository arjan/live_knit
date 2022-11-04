defmodule LiveKnitWeb.Live.Main do
  use LiveKnitWeb, :live_view

  @poll_interval 500

  alias LiveKnit.Control
  alias LiveKnitWeb.Components.{PatternRow, Settings}

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(LiveKnit.PubSub, LiveKnit.Serial.topic())
      Phoenix.PubSub.subscribe(LiveKnit.PubSub, Control.topic())
      Process.send_after(self(), :poll, @poll_interval)
    end

    status = Control.status()
    {:ok, socket |> assign(:control, status) |> assign(:serial_log, [])}
  end

  def handle_event("knit-" <> event, _, socket) do
    Control.set_knitting(event == "start")
    {:noreply, socket}
  end

  def handle_event("reset", _, socket) do
    Control.reset()
    {:noreply, socket}
  end

  def handle_event("step", _, socket) do
    send(Control, :knit)
    {:noreply, socket}
  end

  def handle_event("calibrate", _, socket) do
    send(Control, {:serial_in, "R:fc"})
    {:noreply, socket}
  end

  def handle_event("pattern_end", _, socket) do
    send(Control, {:serial_in, "E:1"})
    {:noreply, socket}
  end

  def handle_info(:poll, socket) do
    Process.send_after(self(), :poll, @poll_interval)
    status = Control.status()
    {:noreply, socket |> assign(:control, status)}
  end

  def handle_info({:status, status}, socket) do
    {:noreply, socket |> assign(:control, status)}
  end

  def handle_info({:serial_in, data}, socket) do
    message = "<-- " <> data
    {:noreply, socket |> assign(:serial_log, [message | socket.assigns.serial_log])}
  end

  def handle_info({:serial_out, data}, socket) do
    message = "--> " <> data
    {:noreply, socket |> assign(:serial_log, [message | socket.assigns.serial_log])}
  end
end
