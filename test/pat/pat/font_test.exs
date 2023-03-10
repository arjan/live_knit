defmodule Pat.FontTest do
  use ExUnit.Case

  alias Pat.Font

  describe "font" do
    test "load" do
      assert_raise RuntimeError, fn -> Font.load(:x) end

      assert font = %Font{} = Font.load(:sigi5)
      assert %Pat{} = font.glyphs["A"]
    end

    test "measure" do
      font = Font.load(:sigi5)
      assert {5, 5} = Font.measure(font, "A")
      assert {11, 5} = Font.measure(font, "AA")
    end

    test "render" do
      font = Font.load(:sigi5b, fg: "X", bg: " ", stride: 2)

      string = "hello there"
      {w, h} = Font.measure(font, string)

      target = Pat.new(w, h, " ")
      target = Font.render(font, target, string, 0, 0)

      assert "XX  XX  XXXXXX  XX      XX       XXXX " <> _ = target.data
    end
  end
end
