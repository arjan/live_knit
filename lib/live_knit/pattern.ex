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

  @spec select_color(row(), non_neg_integer) :: row()
  def select_color(row, color) do
    select_color(row, color, <<>>)
  end

  defp select_color(<<>>, _color, acc), do: acc

  for n <- 0..3 do
    defp select_color(<<unquote(48 + n)::size(8), rest::binary>>, unquote(n), acc) do
      select_color(rest, unquote(n), <<acc::binary, ?1>>)
    end
  end

  defp select_color(<<_::size(8), rest::binary>>, color, acc) do
    select_color(rest, color, <<acc::binary, ?0>>)
  end
end
