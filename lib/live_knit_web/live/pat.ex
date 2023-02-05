defmodule LiveKnitWeb.Live.Pat do
  require Logger

  use LiveKnitWeb, :live_view

  alias LiveKnitWeb.Components.{PatternRow}

  @initial """
  #  font = Pat.Font.load(:sigi5b, fg: "X", bg: " ", stride: 1)

  string = "hello there"
  #  {w, h} = Pat.Font.measure(font, string)
  {w, h} = {20, 10}
  target = Pat.new(w, h, " ")
  #  target = Pat.Font.render(font, target, string, 0, 0)
  """

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket = assign(socket, :canvas, Pat.new(10, 10, "1"))
    {:ok, eval(@initial, socket)}
  end

  @impl Phoenix.LiveView
  def handle_event("update", %{"code" => code}, socket) do
    {:noreply, eval(code, socket)}
  end

  @error_canvas Pat.Font.render(Pat.Font.load(:sigi5), Pat.new(20, 10), "error", 0, 0)

  defp eval(code, socket) do
    {canvas, error_message} =
      case Pat.Dsl.eval(code) do
        {:ok, canvas} ->
          {canvas, nil}

        {:error, message} ->
          IO.inspect(message, label: "message")

          {socket.assigns.canvas, message}
      end

    socket
    |> assign(:code, code)
    |> assign(:canvas, canvas)
    |> assign(:error_message, error_message)
  end
end
