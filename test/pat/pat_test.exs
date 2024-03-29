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

  test "new_text 2" do
    target = Pat.new_text("hello there", font: :arcade, stride: 0)

    assert "1111" <> _ = target.data
  end

  test "new_text" do
    target = Pat.new_text("hello there", font: :sigi5b)

    assert "0011001000" <> _ = target.data
  end

  test "newtext w/ multiple lines" do
    target = Pat.new_text("hello\nthere...!", font: :sigi5b, align: :center)

    assert "11110011001000000100111110011111100001111111111001100100111110011111001111100110011111111100000010000011001111100111110011001111111110011001001111100111110011111001100111111111001100100000010000001000000110000111111111111111111111111111111111111111111111111100000010011001000000100000110000001111111001100111001100100111110011001001111111111100110011100000010000011000001100000111111110011001110011001001111100100110011111111111111100111001100100000010011001000000101010100" =
             target.data
  end

  test "repeat_h" do
    assert %Pat{data: "X X X X ", w: 8, h: 1} = Pat.from_string("X ") |> Pat.repeat_h(4)
    # Pat.from_string("XX \nX X") |> Pat.repeat_h(10) |> IO.puts()
  end

  test "repeat_v" do
    assert %Pat{data: "X X X X X X ", w: 1, h: 12} = Pat.from_string("X\n ") |> Pat.repeat_v(6)

    # Pat.from_string("XX \nX X") |> Pat.repeat_v(10) |> Pat.repeat_h(10) |> IO.puts()
  end

  describe "overlay" do
    test "overlay" do
      #  Pat.new(4, 4, " ")
      target = Pat.from_string("aaaa\nbbbb\ncccc\ndddd")
      source = Pat.new(2, 2, "X")

      output = target |> Pat.overlay(source, {1, 1})
      assert "aaaa\nbXXb\ncXXc\ndddd" = to_string(output)
    end

    test "overlay positions" do
      target = Pat.from_string("aaaa\nbbbb\ncccc\ndddd")
      source = Pat.new(2, 2, "X")

      # output = target |> Pat.overlay(source, :center)
      # assert "aaaa\nbXXb\ncXXc\ndddd" = to_string(output)

      output = target |> Pat.overlay(source, :top)
      assert "aXXa\nbXXb\ncccc\ndddd" = to_string(output)

      output = target |> Pat.overlay(source, :bottom)
      assert "aaaa\nbbbb\ncXXc\ndXXd" = to_string(output)

      output = target |> Pat.overlay(source, :left)
      assert "aaaa\nXXbb\nXXcc\ndddd" = to_string(output)

      output = target |> Pat.overlay(source, :right)
      assert "aaaa\nbbXX\nccXX\ndddd" = to_string(output)
    end

    test "overlay 2" do
      target = Pat.from_string("aaaa\nbbbb\ncccc\ndddd")
      source = Pat.new(4, 1, "X")

      target = target |> Pat.overlay(source, {0, 0})

      assert "XXXX\nbbbb\ncccc\ndddd" = to_string(target)
    end

    test "overlay edge cases" do
      target = Pat.from_string("XXXXXXXX")
      source = Pat.from_string("YYYYYYYY")

      assert "YYYYYYYY" = Pat.overlay(target, source, {0, 0}) |> to_string()
      assert "XXXXYYYY" = Pat.overlay(target, source, {4, 0}) |> to_string()
      assert "XXXXXXXX" = Pat.overlay(target, source, {8, 0}) |> to_string()
      assert "XXXXXXXX" = Pat.overlay(target, source, {10, 0}) |> to_string()

      assert "YYYYYYXX" = Pat.overlay(target, source, {-2, 0}) |> to_string()
      assert "YXXXXXXX" = Pat.overlay(target, source, {-7, 0}) |> to_string()
      assert "XXXXXXXX" = Pat.overlay(target, source, {-8, 0}) |> to_string()
    end

    test "overlay edge cases 2" do
      target = Pat.from_string("XXXX")
      source = Pat.from_string("YYYYYYYY")

      assert "YYYY" = Pat.overlay(target, source, {-2, 0}) |> to_string()
    end

    test "overlay w/ callback" do
      target = Pat.from_string("XXXXXXXX")
      source = Pat.from_string("YYYYYYYY")

      overlay_resolve = fn a, b ->
        send(self(), {:overlay_resolve, a, b})
        "12345678"
      end

      assert "XXXXXXXX" = Pat.overlay(target, source, {8, 0}, overlay_resolve) |> to_string()
      refute_receive({:overlay_resolve, _, _})

      assert "XXXX1234" = Pat.overlay(target, source, {4, 0}, overlay_resolve) |> to_string()
      assert_receive({:overlay_resolve, "XXXX", "YYYY"})
    end

    test "xor" do
      target = Pat.from_string("10101010")
      source = Pat.from_string("00000000")

      assert "01010101" = Pat.overlay(target, source, {0, 0}, :xor) |> to_string()
    end
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

    Pat.new(2, 2, "1")
    |> Pat.concat_h(Pat.new(2, 2, "0"))
    |> Pat.concat_v(Pat.new(4, 2, "2"))

    #    |> IO.puts()
  end

  test "concat_v" do
    target = Pat.concat_v([Pat.new(10, 10, "X"), Pat.new(10, 1, "."), Pat.new(10, 4, "Y")])
    assert target.h == 15
    assert target.w == 10
  end

  test "pad" do
    source = Pat.new(2, 2, "1")
    output = Pat.pad(source, 2)
    assert output.w == 6
    assert output.h == 6
  end

  test "pad_left right etc" do
    assert "00\n11\n11" = Pat.new(2, 2, "1") |> Pat.pad_top(1, "0") |> to_string()
    assert "11\n11\n00" = Pat.new(2, 2, "1") |> Pat.pad_bottom(1, "0") |> to_string()
    assert "011\n011" = Pat.new(2, 2, "1") |> Pat.pad_left(1, "0") |> to_string()
    assert "110\n110" = Pat.new(2, 2, "1") |> Pat.pad_right(1, "0") |> to_string()
  end

  test "invert" do
    target = Pat.new(2, 2, "1") |> Pat.invert()
    assert "0000" = target.data
  end

  test "stretch" do
    pat =
      Pat.from_string("1010101010")
      |> Pat.stretch_h(2.8)

    assert "1110001110011100011000111000" = pat.data
  end

  test "double" do
    pat =
      Pat.from_string("1")
      |> Pat.double()

    assert {2, 2} = {pat.w, pat.h}
    assert "1111" = pat.data
  end

  test "fit" do
    assert "1" = Pat.from_string("0\n1\n0") |> Pat.fit(1, 1) |> to_string()
  end
end
