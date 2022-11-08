defmodule LiveKnitWeb.Live.Main do
  use LiveKnitWeb, :live_view

  alias LiveKnit.{Control, Serial, SerialManager}
  alias LiveKnitWeb.Components.{PatternRow, Settings, DebugPanel}

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Serial.subscribe()
      SerialManager.subscribe()
      Control.subscribe()
    end

    socket =
      socket
      |> assign(:control, Control.status())
      |> assign(:serial_status, SerialManager.status())
      |> assign(:serial_log, [])

    {:ok, socket}
  end

  def handle_event("image-data", data_url, socket) do
    status = Control.status()

    with ["data:image/" <> _, data] <- String.split(data_url, ",", parts: 2),
         {:ok, data} <- Base.decode64(data),
         {:ok, pixels} <- Pixels.read(data) do
      if pixels.width <= status.settings.width * 2 do
        rows = LiveKnit.Pattern.from_pixels(pixels)
        Control.change_settings(%{image: rows})
        {:noreply, socket}
      else
        {:noreply,
         put_flash(socket, :error, "Image is too large (#{pixels.width}) for knit width")}
      end
    else
      _ ->
        {:noreply, put_flash(socket, :error, "Error while reading image")}
    end
  end

  def handle_event("knit-" <> event, _, socket) do
    Control.set_knitting(event == "start")
    {:noreply, socket}
  end

  def handle_event("motor-" <> event, _, socket) do
    Serial.write("M:" <> event)
    {:noreply, socket}
  end

  def handle_event("mode-" <> event, _, socket) do
    Control.set_single_color(event == "single")
    {:noreply, socket}
  end

  def handle_event("reset", _, socket) do
    Control.reset()
    {:noreply, socket}
  end

  def handle_info({:status, status}, socket) do
    {:noreply, socket |> assign(:control, status)}
  end

  def handle_info({:serial_status, status}, socket) do
    {:noreply, socket |> assign(:serial_status, status)}
  end

  def handle_info({:serial_in, data}, socket) do
    message = "<-- " <> data

    {:noreply,
     socket |> assign(:serial_log, [message | socket.assigns.serial_log] |> Enum.slice(0, 20))}
  end

  def handle_info({:serial_out, data}, socket) do
    message = "--> " <> data
    {:noreply, socket |> assign(:serial_log, [message | socket.assigns.serial_log])}
  end

  def knitting_size_class(n) when n < 48, do: "large"
  def knitting_size_class(n) when n < 128, do: "medium"
  def knitting_size_class(_), do: "small"
end
