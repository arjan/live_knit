defmodule LiveKnitWeb.Live.Movie do
  require Logger

  use LiveKnitWeb, :live_view

  alias LiveKnit.Serial

  @cursor_range 1024
  @num_frames 11
  @start_frame 15

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Serial.subscribe()
    end

    socket = assign(socket, :frame, @start_frame)
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:serial_in, "C:" <> data}, socket) do
    {cursor, _} = Integer.parse(data)
    frame = @start_frame + trunc(@num_frames * cursor / @cursor_range)
    {:noreply, socket |> assign(:frame, frame)}
  end

  def handle_info({:serial_in, _}, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <img class="movie" src={"/images/frames/knitting_#{@frame}.png"} />
    """
  end
end
