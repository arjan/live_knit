defmodule LiveKnit.Repo.Migrations.CreatePresets do
  use Ecto.Migration

  def change do
    create table(:presets) do
      add :name, :string
      add :settings, :map

      timestamps()
    end
  end
end
