defmodule LiveKnit.Storage.Pattern do
  use Ecto.Schema
  import Ecto.Changeset

  schema "patterns" do
    field :code, :string
    field :title, :string

    timestamps()
  end

  @doc false
  def changeset(pattern, attrs) do
    pattern
    |> cast(attrs, [:title, :code])
    |> validate_required([:title, :code])
  end
end
