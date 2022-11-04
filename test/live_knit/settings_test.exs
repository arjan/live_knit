defmodule LiveKnit.SettingsTest do
  use ExUnit.Case

  alias LiveKnit.Settings

  test "to_pattern" do
    s = %Settings{width: 10, image: ["0110", "1001"]}
    assert ["0000110000", "0001001000"] = Settings.to_pattern(s)

    s = %Settings{width: 10, image: ["1001"], fill_color: 1}
    assert ["1111001111"] = Settings.to_pattern(s)

    s = %Settings{width: 10, image: ["10"], repeat_x: true}
    assert ["1010101010"] = Settings.to_pattern(s)

    s = %Settings{width: 10, image: ["10"], repeat_x: true, double_x: true}
    assert ["1100110011"] = Settings.to_pattern(s)

    s = %Settings{width: 10, image: ["10"], double_x: true}
    assert ["0001100000"] = Settings.to_pattern(s)

    s = %Settings{width: 10, image: ["10"], repeat_x: true, double_x: true, double_y: true}
    assert ["1100110011", "1100110011"] = Settings.to_pattern(s)
  end

  test "apply settings" do
    assert {:error, "repeat_x is invalid, width is invalid"} =
             Settings.apply(%Settings{}, %{width: "a", repeat_x: 3})

    assert {:ok, %{width: 4}} = Settings.apply(%Settings{}, %{width: 4})
  end
end
