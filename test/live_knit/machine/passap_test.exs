defmodule LiveKnit.Machine.PassapTest do
  use ExUnit.Case

  alias LiveKnit.{Machine, Pattern, Settings}

  test "2 color passap machine" do
    {:ok, pixels} = Pixels.read_file(__DIR__ <> "/../images/dot.png")
    rows = Pattern.from_pixels(pixels)
    settings = %Settings{image: rows, width: 8}

    assert {instructions, machine} = Machine.load(%Machine.Passap{}, settings)

    assert [{:status, %{left_needle: 62, right_needle: 70, direction: :uncalibrated}}] =
             instructions

    assert {instructions, machine} = Machine.calibrated(machine)

    assert [
             {:write, "F:20"},
             {:write, "P:00000000"},
             {:status, %{direction: :rtl, color: -1, rows_remaining: 8}}
           ] = instructions

    assert {instructions, machine} = Machine.knit(machine)

    assert [
             {:write, "F:20"},
             {:write, "P:11111111"},
             {:status, %{direction: :ltr, color: -1, rows_remaining: 8}},
             {:row, "00000000"}
           ] = instructions

    assert {instructions, machine} = Machine.knit(machine)

    assert [{:status, %{direction: :rtl, color: 0}}] = instructions

    assert {instructions, machine} = Machine.knit(machine)

    assert [{:write, "P:00000000"}, {:status, %{direction: :ltr, color: 0}}] = instructions

    assert {instructions, machine} = Machine.knit(machine)

    assert [{:status, %{direction: :rtl, color: 1}}] = instructions

    ## next data row of pixels

    assert {instructions, machine} = Machine.knit(machine)

    assert [
             {:write, "F:20"},
             {:write, "P:10000001"},
             {:status, %{direction: :ltr, color: 1, rows_remaining: 7}},
             {:row, "01111110"}
           ] = instructions

    assert {instructions, machine} = Machine.knit(machine)
    assert [{:status, %{direction: :rtl, color: 0}}] = instructions

    assert {instructions, machine} = Machine.knit(machine)

    assert [{:write, "P:01111110"}, {:status, %{direction: :ltr, color: 0}}] = instructions

    assert {instructions, machine} = Machine.knit(machine)
    assert [{:status, %{direction: :rtl, color: 1}}] = instructions

    # next 6 rows, = 6 * 4 knits..

    machine =
      for _ <- 1..24, reduce: machine do
        machine ->
          {_instructions, machine} = Machine.knit(machine)
          machine
      end

    # now we are done

    assert {[], :done} = Machine.knit(machine)
  end

  test "1 color" do
    settings = %Settings{
      image: ["0"],
      colors: 1,
      repeat_x: true,
      repeat_y: true,
      repeat_y_count: 2,
      width: 8
    }

    assert {_instructions, machine} = Machine.load(%Machine.Passap{}, settings)

    assert {instructions, machine} = Machine.calibrated(machine)

    assert [
             {:write, "F:20"},
             {:write, "P:11111111"},
             {:status, %{direction: :rtl, color: 0, rows_remaining: 2}},
             {:row, "00000000"}
           ] = instructions

    assert {instructions, machine} = Machine.knit(machine)

    assert [{:status, %{direction: :ltr, color: 0}}] = instructions

    assert {instructions, machine} = Machine.knit(machine)

    assert [
             {:write, "F:20"},
             {:write, "P:11111111"},
             {:status, %{direction: :rtl, color: 0}},
             {:row, "00000000"}
           ] = instructions

    assert {instructions, _machine} = Machine.knit(machine)
    assert [{:status, %{direction: :ltr, color: 0}}] = instructions
  end

  test "infinite repeat" do
    settings = %Settings{image: ["11001100"], repeat_y: true, repeat_y_count: 100_000}
    {_, machine} = Machine.load(%Machine.Passap{}, settings)
    assert {_instructions, machine} = Machine.calibrated(machine)

    for _ <- 1..100, reduce: machine do
      machine ->
        {[_ | _], machine} = Machine.knit(machine)
        machine
    end
  end

  test "pattern repeat" do
    settings = %Settings{
      image: ["100", "010", "001"],
      repeat_y: true,
      repeat_x: true,
      width: 80,
      position: 40
    }

    {_, machine} = Machine.load(%Machine.Passap{}, settings)

    assert {_instructions, machine} = Machine.calibrated(machine)

    # skip first empty row
    assert {instructions, _machine} = Machine.knit(machine)

    assert [{:write, "F:50"}, {:write, "P:011011011" <> _}, {:status, _}, {:row, _}] =
             instructions
  end

  test "pattern repeat w/ remaining" do
    settings = %Settings{
      image: ["100", "010", "001"],
      repeat_y: true,
      repeat_x: true,
      width: 80,
      repeat_y_count: 12
    }

    {_, machine} = Machine.load(%Machine.Passap{}, settings)
    assert {_instructions, machine} = Machine.calibrated(machine)
    assert {_instructions, machine} = Machine.knit(machine)
    assert {_instructions, machine} = Machine.knit(machine)
    assert {_instructions, machine} = Machine.knit(machine)
    assert {_instructions, machine} = Machine.knit(machine)

    machine =
      for _ <- 1..(11 * 4), reduce: machine do
        machine ->
          {_instructions, machine} = Machine.knit(machine)
          machine
      end

    # now we are done

    assert {[], :done} = Machine.knit(machine)
  end

  test "peek" do
    settings = %Settings{image: ["100", "010", "001"], repeat_y: true, repeat_x: true, width: 80}
    {_, machine} = Machine.load(%Machine.Passap{}, settings)

    assert ["100100" <> _, "010010" <> _, "001001" <> _, _, _] = Machine.peek(machine, 5)

    ##
    settings = %Settings{image: ["100", "010", "001"], repeat_y: false, repeat_x: true, width: 80}
    {_, machine} = Machine.load(%Machine.Passap{}, settings)

    assert ["100100" <> _, "010010" <> _, "001001" <> _] = Machine.peek(machine, 5)
  end

  test "knitting positioning" do
    settings = %Settings{image: ["100", "010", "001"], position: 90, width: 40}
    {instructions, _} = Machine.load(%Machine.Passap{}, settings)

    assert [{:status, %{left_needle: 50, right_needle: 90, direction: :uncalibrated}}] =
             instructions

    settings = %Settings{image: ["100", "010", "001"], position: -50, width: 40}
    {instructions, _} = Machine.load(%Machine.Passap{}, settings)

    assert [{:status, %{left_needle: -90, right_needle: -50, direction: :uncalibrated}}] =
             instructions
  end

  test "motor control" do
    settings = %Settings{
      image: ["1"],
      repeat_y: true,
      repeat_x: true,
      width: 80,
      repeat_y_count: 1
    }

    {_, machine} = Machine.load(%Machine.Passap{}, settings)

    # motor if on

    {_, machine} = Machine.interpret_serial(machine, "M:1")
    assert machine.motor_on

    assert {_instructions, machine} = Machine.calibrated(machine)
    assert {_instructions, machine} = Machine.knit(machine)
    assert {_instructions, machine} = Machine.knit(machine)
    assert {_instructions, machine} = Machine.knit(machine)
    assert {_instructions, machine} = Machine.knit(machine)

    # now we are done, but get instruction with motor off

    assert {[{:write_delayed, "M:0", 1000}], :done} = Machine.knit(machine)
  end
end
