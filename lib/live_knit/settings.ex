defmodule LiveKnit.Settings do
  alias LiveKnit.{Pattern, Settings}

  @type t :: %__MODULE__{}

  defstruct width: 20,
            image: [],
            repeat_x: false,
            repeat_y: false,
            fill_color: 0,
            double_x: false,
            double_y: false

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
