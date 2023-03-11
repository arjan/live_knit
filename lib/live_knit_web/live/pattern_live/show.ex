defmodule LiveKnitWeb.PatternLive.Show do
  use LiveKnitWeb, :live_view

  alias LiveKnit.Storage

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:pattern, Storage.get_pattern!(id))}
  end

  defp page_title(:show), do: "Show Pattern"
  defp page_title(:edit), do: "Edit Pattern"
end
