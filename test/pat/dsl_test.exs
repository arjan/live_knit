defmodule Pat.DslTest do
  use ExUnit.Case

  test "dsl" do
    result =
      Pat.Dsl.eval("""
      new(10, 10)
      """)

    assert {:ok, %Pat{w: 10, h: 10}} = result
  end
end
