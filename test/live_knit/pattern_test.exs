defmodule LiveKnit.PatternTest do
  use ExUnit.Case

  alias LiveKnit.Pattern

  test "from_pixels" do
    {:ok, pixels} = Pixels.read_file(__DIR__ <> "/images/dot.png")

    assert ["00000000" | _] = Pattern.from_pixels(pixels)
  end

  test "invert_row" do
    assert "00101001" == Pattern.invert_row("11010110")
  end
end
