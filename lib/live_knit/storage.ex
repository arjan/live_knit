defmodule LiveKnit.Storage do
  alias LiveKnit.Repo

  alias LiveKnit.Storage.Preset

  @doc """
  Returns the list of presets.
  """
  def list_presets do
    Repo.all(Preset)
  end

  @doc """
  Gets a single preset.
  """
  def get_preset!(id), do: Repo.get!(Preset, id)

  @doc """
  Creates a preset.
  """
  def create_preset(attrs \\ %{}) do
    %Preset{}
    |> Preset.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a preset.
  """
  def update_preset(%Preset{} = preset, attrs) do
    preset
    |> Preset.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a preset.
  """
  def delete_preset(%Preset{} = preset) do
    Repo.delete(preset)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking preset changes.
  """
  def change_preset(%Preset{} = preset, attrs \\ %{}) do
    Preset.changeset(preset, attrs)
  end
end
