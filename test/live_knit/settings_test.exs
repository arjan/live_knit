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
  end
end
