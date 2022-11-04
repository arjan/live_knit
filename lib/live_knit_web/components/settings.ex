defmodule LiveKnitWeb.Components.Settings do
  use LiveKnitWeb, :live_component

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

    case LiveKnit.Control.change_settings(update) do
      :ok ->
        {:noreply, put_flash(socket, :info, "Settings saved")}

      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}
    end
  end
end
