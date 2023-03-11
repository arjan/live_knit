defmodule LiveKnitWeb.PatternLive.Index do
  use LiveKnitWeb, :live_view

  alias LiveKnit.Storage
  alias LiveKnit.Storage.Pattern

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :patterns, list_patterns())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Pattern")
    |> assign(:pattern, Storage.get_pattern!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Pattern")
    |> assign(:pattern, %Pattern{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Patterns")
    |> assign(:pattern, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    pattern = Storage.get_pattern!(id)
    {:ok, _} = Storage.delete_pattern(pattern)

    {:noreply, assign(socket, :patterns, list_patterns())}
  end

  defp list_patterns do
    Storage.list_patterns()
  end
end
