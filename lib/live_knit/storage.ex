defmodule LiveKnit.Storage do
  alias LiveKnit.Settings
  alias LiveKnit.Repo

  alias LiveKnit.Storage.Preset

  def load(name) do
    case Repo.get_by(Preset, name: name) do
      nil ->
        {:ok, %Settings{}}

      preset ->
        Settings.load(preset.settings)
    end
  end

  def save(name, settings) do
    attrs = %{name: name, settings: settings}

    case Repo.get_by(Preset, name: name) do
      nil ->
        create_preset(attrs)

      preset ->
        update_preset(preset, attrs)
    end
  end

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
