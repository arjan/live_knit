defmodule PatTest do
  use ExUnit.Case

  alias Pat.Canvas
  alias Pat.Font

  describe "canvas" do
    test "new canvas" do
      c = Canvas.new(2, 2) |> Canvas.set(0, 0, "1") |> Canvas.set(1, 1, "1")
      assert "1001" == c.data
    end

    test "transform" do
      c = Canvas.new(3, 3) |> Canvas.set(0, 0, "1") |> Canvas.set(1, 1, "1")
      assert "000010100" = Canvas.transform(c, :hflip).data
      assert "001010000" = Canvas.transform(c, :vflip).data
      assert "000010001" = Canvas.transform(c, :r180).data

      c = Canvas.new(2, 3) |> Canvas.set(0, 0, "1") |> Canvas.set(1, 1, "1")

      assert "010100" = Canvas.transform(c, :rccw).data
      assert "001010" = Canvas.transform(c, :rcw).data
    end

    test "set multiple pixels, crop" do
      c =
        Canvas.new(8, 2)
        |> Canvas.set(4, 0, "111111")

      assert "0000111100000000" == c.data
    end

    test "rows" do
      assert ["00", "00"] = Canvas.new(2, 2) |> Canvas.rows()
    end

    test "set canvas" do
      c = Canvas.new(4, 4)
      c2 = Canvas.new(2, 2, "1")

      assert ["0000", "0110", "0110", "0000"] = Canvas.set(c, 1, 1, c2) |> Canvas.rows()
    end
  end

  describe "font" do
    test "load" do
      assert_raise RuntimeError, fn -> Font.load(:x) end

      assert font = %Font{} = Font.load(:sigi5)
      assert %Canvas{} = font.glyphs["A"]
    end

    test "measure" do
      font = Font.load(:sigi5)
      assert {5, 5} = Font.measure(font, "A")
      assert {11, 5} = Font.measure(font, "AA")
    end

    test "render" do
      font = Font.load(:sigi5c, fg: "X", bg: " ", stride: 1)

      string = "arjan"
      {w, h} = Font.measure(font, string)

      target = Canvas.new(w, h, " ")
      target = Font.render(font, target, string, 0, 0)

      assert " XX  XXX     X  XX  X  X" <> _ = target.data
    end
  end
end
