defmodule LiveKnitWeb.Live.Pat do
  require Logger

  use LiveKnitWeb, :live_view

  import LiveKnitWeb.Components.ComponentLibrary
  alias LiveKnit.Storage

  @initial """
  new(20,10)
  """

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:canvas, Pat.new(10, 10, "1"))
      |> assign(:code, @initial)
      |> load_data()
      |> eval()

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("update", %{"code" => code}, socket) do
    {:noreply, assign(socket, :code, code) |> eval()}
  end

  def handle_event("form", params, socket) do
    {:noreply, socket |> assign(:form, params)}
  end

  def handle_event("pattern-load", %{}, socket) do
    socket =
      load_pattern(socket, Storage.get_pattern(String.to_integer(socket.assigns.form["id"] || 0)))
      |> eval()

    {:noreply, socket}
  end

  def handle_event("pattern-save", %{}, socket) do
    # Storage.get_pattern(String.to_integer(socket.assigns.form["id"] || 0))
    IO.inspect(socket.assigns.form["id"], label: "socket.assigns.form[id]")
    attrs = %{code: socket.assigns.code, title: socket.assigns.form["title"]}

    {:ok, pattern} =
      case socket.assigns.form["id"] do
        "" ->
          Storage.create_pattern(attrs)

        id ->
          Storage.get_pattern(String.to_integer(id) || 0)
          |> Storage.update_pattern(attrs)
      end

    {:noreply, socket |> load_data() |> load_pattern(pattern)}
  end

  def handle_event("pattern-delete", _, socket) do
    socket =
      case Storage.get_pattern(String.to_integer(socket.assigns.form["id"] || 0)) do
        nil ->
          socket
          |> put_flash(:info, "failed to delete")

        %{} = pattern ->
          Storage.delete_pattern(pattern)

          load_data(socket)
          |> put_flash(:info, "pattern deleted")
      end

    {:noreply, socket}
  end

  ###
  defp eval(socket) do
    {canvas, error_message} =
      case Pat.Dsl.eval(socket.assigns.code) do
        {:ok, canvas} ->
          {canvas, nil}

        {:error, message} ->
          IO.inspect(message, label: "message")

          {socket.assigns.canvas, message}
      end

    socket
    |> assign(:canvas, canvas)
    |> assign(:error_message, error_message)
  end

  defp load_data(socket) do
    patterns = Storage.list_patterns()

    socket
    |> assign(:patterns, patterns)
    |> assign(:form, %{})
    |> load_pattern(List.first(patterns))
  end

  defp load_pattern(socket, nil), do: socket

  defp load_pattern(socket, pattern) do
    socket
    |> assign(:pattern, pattern)
    |> assign(:code, pattern.code)
    |> assign(:form, %{"id" => to_string(pattern.id), "title" => pattern.title})
  end
end
