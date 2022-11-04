defmodule LiveKnitWeb.Components.Settings do
  use LiveKnitWeb, :live_component

  alias LiveKnit.Control

  def handle_event("save", attrs, socket) do
    default_bools =
      Map.from_struct(socket.assigns.settings)
      |> Enum.filter(&is_boolean(elem(&1, 1)))
      |> Enum.map(fn {k, _} -> {to_string(k), false} end)

    update =
      Map.new(
        default_bools ++
          Enum.map(
            attrs,
            fn
              {k, "on"} -> {k, true}
              {"image", data} -> {"image", String.split(data, "\n")}
              kv -> kv
            end
          )
      )

    change_settings(update, socket)
  end

  def handle_event("width-" <> dir, _attrs, socket) do
    delta =
      case dir do
        "plus" -> 1
        "minus" -> -1
      end

    status = Control.status()
    change_settings(%{width: status.settings.width + delta}, socket)
  end

  defp change_settings(update, socket) do
    case LiveKnit.Control.change_settings(update) do
      :ok ->
        {:noreply, socket}

      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}
    end
  end
end
