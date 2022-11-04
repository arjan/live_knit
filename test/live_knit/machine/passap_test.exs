defmodule LiveKnit.Machine.PassapTest do
  use ExUnit.Case

  alias LiveKnit.Machine
  alias LiveKnit.Pattern

  test "passap machine" do
    {:ok, pixels} = Pixels.read_file(__DIR__ <> "/../images/dot.png")
    rows = Pattern.from_pixels(pixels)

    machine = Machine.load(%Machine.Passap{repeat: false}, rows)

    assert {instructions, machine} = Machine.knit(machine)
    assert [{:write, "P:00000000"}, {:status, %{direction: :rtl, color: 0}}] = instructions

    assert {instructions, machine} = Machine.knit(machine)
    assert [{:status, %{direction: :ltr, color: 0}}] = instructions

    assert {instructions, machine} = Machine.knit(machine)
    assert [{:write, "P:11111111"}, {:status, %{direction: :rtl, color: 1}}] = instructions

    assert {instructions, machine} = Machine.knit(machine)
    assert [{:status, %{direction: :ltr, color: 1}}] = instructions

    ## next data row of pixels

    assert {instructions, machine} = Machine.knit(machine)
    assert [{:write, "P:01111110"}, {:status, %{direction: :rtl, color: 0}}] = instructions

    assert {instructions, machine} = Machine.knit(machine)
    assert [{:status, %{direction: :ltr, color: 0}}] = instructions

    assert {instructions, machine} = Machine.knit(machine)
    assert [{:write, "P:10000001"}, {:status, %{direction: :rtl, color: 1}}] = instructions

    assert {instructions, machine} = Machine.knit(machine)
    assert [{:status, %{direction: :ltr, color: 1}}] = instructions

    # next 6 rows, = 6 * 4 knits..

    machine =
      for n <- 1..24, reduce: machine do
        machine ->
          {_instructions, machine} = Machine.knit(machine)
          machine
      end

    # now we are done

    assert :done = Machine.knit(machine)
  end

  test "infinite repeat" do
    machine = Machine.load(%Machine.Passap{repeat: true}, ["11001100"])

    for _ <- 1..100, reduce: machine do
      machine -> Machine.knit(machine) |> elem(1)
    end
  end
end
