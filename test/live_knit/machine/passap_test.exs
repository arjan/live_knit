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
             {:write, "F:94"},
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
             {:write, "F:94"},
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

    assert [{:write, "F:130"}, {:write, "P:100100100" <> _}, {:status, _}, {:row, _}] =
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
end
