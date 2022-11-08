defmodule LiveKnit.PatternTest do
  use ExUnit.Case

  alias LiveKnit.Pattern

  test "from_pixels" do
    {:ok, pixels} = Pixels.read_file(__DIR__ <> "/images/dot.png")

    assert ["00000000" | _] = Pattern.from_pixels(pixels)
  end

  test "select_color" do
    assert "1000" == Pattern.select_color("0123", 0)

    assert "0010" == Pattern.select_color("2201", 0)
    assert "0001" == Pattern.select_color("2201", 1)
    assert "1100" == Pattern.select_color("2201", 2)
    assert "0000" == Pattern.select_color("2201", 3)
  end
end
