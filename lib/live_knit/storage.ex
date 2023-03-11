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

  alias LiveKnit.Storage.Pattern

  @doc """
  Returns the list of patterns.

  ## Examples

      iex> list_patterns()
      [%Pattern{}, ...]

  """
  def list_patterns do
    Repo.all(Pattern)
  end

  @doc """
  Gets a single pattern.

  Raises `Ecto.NoResultsError` if the Pattern does not exist.

  ## Examples

      iex> get_pattern!(123)
      %Pattern{}

      iex> get_pattern!(456)
      ** (Ecto.NoResultsError)

  """
  def get_pattern!(id), do: Repo.get!(Pattern, id)

  def get_pattern(id), do: Repo.get(Pattern, id)

  @doc """
  Creates a pattern.

  ## Examples

      iex> create_pattern(%{field: value})
      {:ok, %Pattern{}}

      iex> create_pattern(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_pattern(attrs \\ %{}) do
    %Pattern{}
    |> Pattern.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a pattern.

  ## Examples

      iex> update_pattern(pattern, %{field: new_value})
      {:ok, %Pattern{}}

      iex> update_pattern(pattern, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_pattern(%Pattern{} = pattern, attrs) do
    pattern
    |> Pattern.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a pattern.

  ## Examples

      iex> delete_pattern(pattern)
      {:ok, %Pattern{}}

      iex> delete_pattern(pattern)
      {:error, %Ecto.Changeset{}}

  """
  def delete_pattern(%Pattern{} = pattern) do
    Repo.delete(pattern)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking pattern changes.

  ## Examples

      iex> change_pattern(pattern)
      %Ecto.Changeset{data: %Pattern{}}

  """
  def change_pattern(%Pattern{} = pattern, attrs \\ %{}) do
    Pattern.changeset(pattern, attrs)
  end
end
