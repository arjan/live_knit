defmodule LiveKnit.Settings do
  use Ecto.Schema
  import Ecto.Changeset

  alias LiveKnit.{Pattern, Settings}

  @type t :: %__MODULE__{}

  @derive Jason.Encoder
  @primary_key false
  embedded_schema do
    field(:width, :integer, default: 20)
    field(:image, {:array, :string}, default: [])
    field(:fill_color, :integer, default: 0)
    field(:repeat_x, :boolean, default: false)
    field(:repeat_y, :boolean, default: false)
    field(:double_x, :boolean, default: false)
    field(:double_y, :boolean, default: false)
    # around which needle on the bed to knit
    field(:center, :integer, default: 0)
  end

  @fields [:width, :image, :fill_color, :repeat_x, :repeat_y, :double_x, :double_y, :center]

  def apply(struct, attrs) do
    struct
    |> cast(attrs, @fields)
    |> validate_number(:width, greater_than_or_equal_to: 1, less_than_or_equal_to: 180)
    |> validate_number(:center, greater_than_or_equal_to: -90, less_than_or_equal_to: 90)
    |> apply_action(:update)
    |> case do
      {:ok, _} = r ->
        r

      {:error, cs} ->
        {:error,
         Ecto.Changeset.traverse_errors(cs, fn _cs, field, {msg, _opts} ->
           [to_string(field), " ", msg]
         end)
         |> Map.values()
         |> Enum.intersperse(", ")
         |> to_string()}
    end
  end

  @spec to_pattern(t()) :: [Pattern.row()]
  def to_pattern(settings) do
    image_rows(settings) |> Enum.map(&to_pattern_row(&1, settings))
  end

  defp image_rows(%Settings{double_y: true} = settings) do
    Enum.flat_map(settings.image, &[&1, &1])
  end

  defp image_rows(settings) do
    settings.image
  end

  defp to_pattern_row(row, settings) do
    row =
      case settings.double_x do
        false -> row
        true -> to_string(for <<color::8 <- row>>, do: <<color, color>>)
      end

    row =
      case settings.repeat_x do
        false -> row
        true -> String.duplicate(row, ceil(settings.width / String.length(row)))
      end

    rl = String.length(row)
    pad = rl + floor((settings.width - rl) / 2)

    row
    |> String.pad_leading(pad, color_byte(settings.fill_color))
    |> String.pad_trailing(settings.width, color_byte(settings.fill_color))
    |> String.slice(0, settings.width)
  end

  defp color_byte(0), do: "0"
  defp color_byte(1), do: "1"
end
