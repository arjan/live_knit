defmodule LiveKnit.StorageFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LiveKnit.Storage` context.
  """

  @doc """
  Generate a preset.
  """
  def preset_fixture(attrs \\ %{}) do
    {:ok, preset} =
      attrs
      |> Enum.into(%{
        name: "some name",
        settings: %{}
      })
      |> LiveKnit.Storage.create_preset()

    preset
  end
end
