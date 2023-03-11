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

  @doc """
  Generate a pattern.
  """
  def pattern_fixture(attrs \\ %{}) do
    {:ok, pattern} =
      attrs
      |> Enum.into(%{
        code: "some code",
        title: "some title"
      })
      |> LiveKnit.Storage.create_pattern()

    pattern
  end
end
