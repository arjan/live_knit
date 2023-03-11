defmodule LiveKnit.Repo.Migrations.CreatePatterns do
  use Ecto.Migration

  def change do
    create table(:patterns) do
      add :title, :string
      add :code, :string

      timestamps()
    end
  end
end
