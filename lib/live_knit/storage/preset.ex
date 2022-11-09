defmodule LiveKnit.Storage.Preset do
  use Ecto.Schema
  import Ecto.Changeset

  schema "presets" do
    field :name, :string
    field :settings, :map

    timestamps()
  end

  @doc false
  def changeset(preset, attrs) do
    preset
    |> cast(attrs, [:name, :settings])
    |> validate_required([:name, :settings])
  end
end
