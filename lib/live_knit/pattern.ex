defmodule LiveKnit.Pattern do
  @type row() :: String.t()

  @spec from_pixels(Pixels.t()) :: [row()]
  def from_pixels(pixels) do
    pixel_data_to_pattern_string(pixels.data, <<>>) |> split_into_rows(pixels.width, [])
  end

  defp pixel_data_to_pattern_string(
         <<r::size(8), _g::size(8), _b::size(8), _a::size(8), rest::binary>>,
         acc
       ) do
    case r > 20 do
      true -> pixel_data_to_pattern_string(rest, <<acc::binary, ?1>>)
      false -> pixel_data_to_pattern_string(rest, <<acc::binary, ?0>>)
    end
  end

  defp pixel_data_to_pattern_string(<<>>, acc) do
    acc
  end

  defp split_into_rows(<<>>, _width, acc) do
    acc
  end

  defp split_into_rows(data, width, acc) do
    {row, rest} = String.split_at(data, width)
    split_into_rows(rest, width, [row | acc])
  end

  @spec invert_row(row()) :: row()
  def invert_row(row) do
    invert_row(row, <<>>)
  end

  defp invert_row(<<>>, acc), do: acc

  defp invert_row(<<?1, rest::binary>>, acc) do
    invert_row(rest, <<acc::binary, ?0>>)
  end

  defp invert_row(<<?0, rest::binary>>, acc) do
    invert_row(rest, <<acc::binary, ?1>>)
  end
end
