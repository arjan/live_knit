defmodule LiveKnitWeb.Live.Main do
  use LiveKnitWeb, :live_view

  @poll_interval 500

  alias LiveKnit.Control

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(LiveKnit.PubSub, LiveKnit.Serial.topic())
      Process.send_after(self(), :poll, @poll_interval)
    end

    status = Control.status()
    {:ok, socket |> assign(:control, status)}
  end

  def render(assigns) do
    ~H"""
    Hello
    <pre>    <%= Jason.encode!(@control, pretty: true) %></pre>
    """
  end

  def handle_info(:poll, socket) do
    Process.send_after(self(), :poll, @poll_interval)
    status = Control.status()
    {:noreply, socket |> assign(:control, status)}
  end
end
