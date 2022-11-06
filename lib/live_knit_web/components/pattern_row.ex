defmodule LiveKnitWeb.Components.PatternRow do
  use LiveKnitWeb, :component

  def row(assigns) do
    ~H"""
    <div class={"row #{current(assigns[:current])}"}>
    <%= for {col, index} <- Enum.with_index(String.split(@row, "", trim: true)) do %>
    <div class={"col yarn color-#{col} #{assigns[:current] && assigns[:status] && highlight_cursor(@status, index)}"}></div>
    <% end %>
    </div>
    """
  end

  def current(true), do: "current"
  def current(_), do: nil

  def highlight_cursor(status, index) do
    if status.left_needle + index == status.position do
      "cursor"
    else
      ""
    end
  end

  def col_class("0"), do: "col bg-dark"
  def col_class("1"), do: "col bg-light"
  def col_class(_), do: "col bg-danger"

  defdelegate cursor_to_needle(c), to: LiveKnit.Machine.Passap
end
