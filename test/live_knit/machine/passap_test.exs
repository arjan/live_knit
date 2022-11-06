defmodule LiveKnit.Machine.PassapTest do
  use ExUnit.Case

  alias LiveKnit.{Machine, Pattern, Settings}

  test "passap machine" do
    {:ok, pixels} = Pixels.read_file(__DIR__ <> "/../images/dot.png")
    rows = Pattern.from_pixels(pixels)
    settings = %Settings{image: rows, width: 8}

    assert {instructions, machine} = Machine.load(%Machine.Passap{}, settings)

    assert [{:status, %{left_needle: -4, right_needle: 4, direction: :uncalibrated}}] =
             instructions

    assert {instructions, machine} = Machine.calibrated(machine)

    assert [
             {:write, "F:86"},
             {:write, "P:00000000"},
             {:status, %{direction: :rtl, color: 0}},
             {:row, "00000000"}
           ] = instructions

    assert {instructions, machine} = Machine.knit(machine)

    assert [{:status, %{direction: :ltr, color: 0}}] = instructions

    assert {instructions, machine} = Machine.knit(machine)

    assert [{:write, "P:11111111"}, {:status, %{direction: :rtl, color: 1}}] = instructions

    assert {instructions, machine} = Machine.knit(machine)
    assert [{:status, %{direction: :ltr, color: 1}}] = instructions

    ## next data row of pixels

    assert {instructions, machine} = Machine.knit(machine)

    assert [
             {:write, "F:86"},
             {:write, "P:01111110"},
             {:status, %{direction: :rtl, color: 0}},
             {:row, "01111110"}
           ] = instructions

    assert {instructions, machine} = Machine.knit(machine)
    assert [{:status, %{direction: :ltr, color: 0}}] = instructions

    assert {instructions, machine} = Machine.knit(machine)

    assert [{:write, "P:10000001"}, {:status, %{direction: :rtl, color: 1}}] = instructions

    assert {instructions, machine} = Machine.knit(machine)
    assert [{:status, %{direction: :ltr, color: 1}}] = instructions

    # next 6 rows, = 6 * 4 knits..

    machine =
      for _ <- 1..24, reduce: machine do
        machine ->
          {_instructions, machine} = Machine.knit(machine)
          machine
      end

    # now we are done

    assert :done = Machine.knit(machine)
  end

  test "infinite repeat" do
    settings = %Settings{image: ["11001100"], repeat_y: true}
    {_, machine} = Machine.load(%Machine.Passap{}, settings)
    assert {_instructions, machine} = Machine.calibrated(machine)

    for _ <- 1..100, reduce: machine do
      machine ->
        {[_ | _], machine} = Machine.knit(machine)
        machine
    end
  end

  test "pattern repeat" do
    settings = %Settings{image: ["100", "010", "001"], repeat_y: true, repeat_x: true, width: 80}
    {_, machine} = Machine.load(%Machine.Passap{}, settings)

    assert {instructions, _machine} = Machine.calibrated(machine)

    assert [{:write, "F:50"}, {:write, "P:100100100" <> _}, {:status, _}, {:row, _}] =
             instructions
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

  test "serial" do
    settings = %Settings{image: ["100", "010", "001"], repeat_y: true, repeat_x: true, width: 40}
    {_, machine} = Machine.load(%Machine.Passap{}, settings)

    {[status: %{position: 90}], _} = Machine.interpret_serial(machine, "C:-2")
    {[status: %{position: 0}], _} = Machine.interpret_serial(machine, "C:178")
  end

  test "knitting positioning" do
    settings = %Settings{image: ["100", "010", "001"], center: 73, width: 40}
    {instructions, _} = Machine.load(%Machine.Passap{}, settings)

    assert [{:status, %{left_needle: 50, right_needle: 90, direction: :uncalibrated}}] =
             instructions

    settings = %Settings{image: ["100", "010", "001"], center: -90, width: 40}
    {instructions, _} = Machine.load(%Machine.Passap{}, settings)

    assert [{:status, %{left_needle: -90, right_needle: -50, direction: :uncalibrated}}] =
             instructions
  end
end
