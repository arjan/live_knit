defmodule PatTest do
  use ExUnit.Case

  alias Pat.Font

  describe "canvas" do
    test "new canvas" do
      c = Pat.new(2, 2) |> Pat.set(0, 0, "1") |> Pat.set(1, 1, "1")
      assert "1001" == c.data
    end

    test "transform" do
      c = Pat.new(3, 3) |> Pat.set(0, 0, "1") |> Pat.set(1, 1, "1")
      assert "000010100" = Pat.transform(c, :hflip).data
      assert "001010000" = Pat.transform(c, :vflip).data
      assert "000010001" = Pat.transform(c, :r180).data

      c = Pat.new(2, 3) |> Pat.set(0, 0, "1") |> Pat.set(1, 1, "1")

      assert "010100" = Pat.transform(c, :rccw).data
      assert "001010" = Pat.transform(c, :rcw).data
    end

    test "set multiple pixels, crop" do
      c =
        Pat.new(8, 2)
        |> Pat.set(4, 0, "111111")

      assert "0000111100000000" == c.data
    end

    test "rows" do
      assert ["00", "00"] = Pat.new(2, 2) |> Pat.rows()
    end

    test "set canvas" do
      c = Pat.new(4, 4)
      c2 = Pat.new(2, 2, "1")

      assert ["0000", "0110", "0110", "0000"] = Pat.set(c, 1, 1, c2) |> Pat.rows()
    end
  end

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
      font = Font.load(:sigi5b, fg: "X", bg: " ", stride: 1)

      string = "hello there"
      {w, h} = Font.measure(font, string)

      target = Pat.new(w, h, " ")
      target = Font.render(font, target, string, 0, 0)

      Pat.print(target)

      assert " XX  XXX     X  XX  X  X" <> _ = target.data
    end
  end
end
