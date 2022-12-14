defmodule LiveKnitWeb.Components.Settings do
  use LiveKnitWeb, :live_component

  alias LiveKnit.Control

  def handle_event("save", attrs, socket) do
    default_bools =
      case socket.assigns.settings.colors > 1 do
        true ->
          Map.from_struct(socket.assigns.settings)
          |> Enum.filter(&is_boolean(elem(&1, 1)))
          |> Enum.map(fn {k, _} -> {to_string(k), false} end)

        false ->
          []
      end

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

  def handle_event("change-" <> attr, %{"value" => value}, socket) do
    attr = String.to_existing_atom(attr)
    change_settings(%{attr => String.to_integer(value)}, socket)
  end

  def handle_event("inc-" <> attr, _attrs, socket), do: incdec(attr, 1, socket)
  def handle_event("dec-" <> attr, _attrs, socket), do: incdec(attr, -1, socket)

  def handle_event("position-" <> dir, _attrs, socket) do
    status = Control.status()
    change_settings(%{position: status.settings.position + dir(dir)}, socket)
  end

  defp dir("plus"), do: 1
  defp dir("minus"), do: -1

  defp change_settings(update, socket) do
    case LiveKnit.Control.change_settings(update) do
      :ok ->
        {:noreply, socket}

      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}
    end
  end

  def range(assigns) do
    ~H"""
    <div class="col">
      <label for={@name <> "-range"} class="form-label"><%= @label %></label>
      <div class="input-group input-group-sm">
        <button type="button" class="btn btn-secondary" phx-click={"dec-" <> @name} disabled={@disabled} phx-target={@target}>&lt;</button>
        <input class="form-control text-center" type="number" phx-blur={"change-" <> @name} phx-target={@target} value={@value} />
        <button type="button" class="btn btn-secondary" phx-click={"inc-" <> @name} disabled={@disabled} phx-target={@target}>&gt;</button>
      </div>
    </div>
    """
  end

  defp incdec(attr, delta, socket) do
    attr = String.to_existing_atom(attr)
    status = Control.status()
    change_settings(%{attr => Map.get(status.settings, attr) + delta}, socket)
  end
end
