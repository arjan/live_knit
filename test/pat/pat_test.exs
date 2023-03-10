defmodule PatTest do
  use ExUnit.Case

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

  test "from_string / to_string" do
    assert %Pat{w: 2, h: 2} = pat = Pat.from_string("X \n X")
    assert "X  X" = pat.data
  end

  test "new_text" do
    target = Pat.new_text("hello there", font: :sigi5b)

    assert "XX  XX  XXXXXX  XX      XX       XXXX " <> _ = target.data
  end

  test "repeat_h" do
    assert %Pat{data: "X X X X ", w: 8, h: 1} = Pat.from_string("X ") |> Pat.repeat_h(4)
    # Pat.from_string("XX \nX X") |> Pat.repeat_h(10) |> IO.puts()
  end

  test "repeat_v" do
    assert %Pat{data: "X X X X X X ", w: 1, h: 12} = Pat.from_string("X\n ") |> Pat.repeat_v(6)

    # Pat.from_string("XX \nX X") |> Pat.repeat_v(10) |> Pat.repeat_h(10) |> IO.puts()
  end

  test "overlay" do
    #  Pat.new(4, 4, " ")
    target = Pat.from_string("aaaa\nbbbb\ncccc\ndddd")
    source = Pat.new(2, 2, "X")

    target = target |> Pat.overlay(source, 1, 1)

    assert "aaaa\nbXXb\ncXXc\ndddd" = to_string(target)
  end

  test "overlay 2" do
    target = Pat.from_string("aaaa\nbbbb\ncccc\ndddd")
    source = Pat.new(4, 1, "X")

    target = target |> Pat.overlay(source, 0, 0)

    assert "XXXX\nbbbb\ncccc\ndddd" = to_string(target)
  end

  test "overlay edge cases" do
    target = Pat.from_string("XXXXXXXX")
    source = Pat.from_string("YYYYYYYY")

    assert "YYYYYYYY" = Pat.overlay(target, source, 0, 0) |> to_string()
    assert "XXXXYYYY" = Pat.overlay(target, source, 4, 0) |> to_string()
    assert "XXXXXXXX" = Pat.overlay(target, source, 8, 0) |> to_string()
    assert "XXXXXXXX" = Pat.overlay(target, source, 10, 0) |> to_string()

    assert "YYYYYYXX" = Pat.overlay(target, source, -2, 0) |> to_string()
    assert "YXXXXXXX" = Pat.overlay(target, source, -7, 0) |> to_string()
    assert "XXXXXXXX" = Pat.overlay(target, source, -8, 0) |> to_string()
  end

  test "overlay w/ callback" do
    target = Pat.from_string("XXXXXXXX")
    source = Pat.from_string("YYYYYYYY")

    overlay_resolve = fn a, b ->
      send(self(), {:overlay_resolve, a, b})
      "12345678"
    end

    assert "XXXXXXXX" = Pat.overlay(target, source, 8, 0, overlay_resolve) |> to_string()
    refute_receive({:overlay_resolve, _, _})

    assert "XXXX1234" = Pat.overlay(target, source, 4, 0, overlay_resolve) |> to_string()
    assert_receive({:overlay_resolve, "XXXX", "YYYY"})
  end

  test "border" do
    target = Pat.new(10, 10, " ")
    border = Pat.from_string("AB\nBA")

    target = target |> Pat.border(border, flip: false)

    assert "ABABABABAB\nBABABABABA\nAB      AB\nBA      BA\nAB      AB\nBA      BA\nAB      AB\nBA      BA\nABABABABAB\nBABABABABA" =
             target |> to_string

    target = target |> Pat.border(border, flip: true)

    assert "ABABABABAB\nBABABABABA\nAB      BA\nBA      AB\nAB      BA\nBA      AB\nAB      BA\nBA      AB\nBABABABABA\nABABABABAB" =
             target |> to_string
  end

  test "concat_h" do
    target = Pat.concat_h([Pat.new(10, 10, "X"), Pat.new(5, 10, "Y"), Pat.new(5, 10, "X")])
    assert target.w == 20
    assert target.h == 10

    assert "XXXXXXXXXXYYYYYXXXXX" <> _ = target.data
  end

  test "concat_v" do
    target = Pat.concat_v([Pat.new(10, 10, "X"), Pat.new(10, 1, "."), Pat.new(10, 4, "Y")])
    assert target.h == 15
    assert target.w == 10
  end
end
