defmodule LiveKnitTest do
  use ExUnit.Case
  doctest LiveKnit

  test "greets the world" do
    assert LiveKnit.hello() == :world
  end
end
