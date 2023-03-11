defmodule LiveKnitWeb.PatternLive.FormComponent do
  use LiveKnitWeb, :live_component

  alias LiveKnit.Storage

  @impl true
  def update(%{pattern: pattern} = assigns, socket) do
    changeset = Storage.change_pattern(pattern)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"pattern" => pattern_params}, socket) do
    changeset =
      socket.assigns.pattern
      |> Storage.change_pattern(pattern_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"pattern" => pattern_params}, socket) do
    save_pattern(socket, socket.assigns.action, pattern_params)
  end

  defp save_pattern(socket, :edit, pattern_params) do
    case Storage.update_pattern(socket.assigns.pattern, pattern_params) do
      {:ok, _pattern} ->
        {:noreply,
         socket
         |> put_flash(:info, "Pattern updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_pattern(socket, :new, pattern_params) do
    case Storage.create_pattern(pattern_params) do
      {:ok, _pattern} ->
        {:noreply,
         socket
         |> put_flash(:info, "Pattern created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
