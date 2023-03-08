defmodule LiveKnitWeb.Components.ComponentLibrary do
  use LiveKnitWeb, :component

  def row(assigns) do
    ~H"""
    <div class={"row #{current(assigns[:current])}"}>
    <%= for col <- String.split(@row, "", trim: true) do %>
    <div class={"col yarn color-#{col}"}></div>
    <% end %>
    </div>
    """
  end

  def current(true), do: "current"
  def current(_), do: nil

  def col_class("0"), do: "col bg-dark"
  def col_class("1"), do: "col bg-light"
  def col_class(_), do: "col bg-danger"
end
