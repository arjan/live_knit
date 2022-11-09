defmodule LiveKnit.StorageTest do
  use LiveKnit.DataCase

  alias LiveKnit.Storage

  describe "presets" do
    alias LiveKnit.Storage.Preset

    import LiveKnit.StorageFixtures

    @invalid_attrs %{name: nil, settings: nil}

    test "list_presets/0 returns all presets" do
      preset = preset_fixture()
      assert Storage.list_presets() == [preset]
    end

    test "get_preset!/1 returns the preset with given id" do
      preset = preset_fixture()
      assert Storage.get_preset!(preset.id) == preset
    end

    test "create_preset/1 with valid data creates a preset" do
      valid_attrs = %{name: "some name", settings: %{}}

      assert {:ok, %Preset{} = preset} = Storage.create_preset(valid_attrs)
      assert preset.name == "some name"
      assert preset.settings == %{}
    end

    test "create_preset/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Storage.create_preset(@invalid_attrs)
    end

    test "update_preset/2 with valid data updates the preset" do
      preset = preset_fixture()
      update_attrs = %{name: "some updated name", settings: %{}}

      assert {:ok, %Preset{} = preset} = Storage.update_preset(preset, update_attrs)
      assert preset.name == "some updated name"
      assert preset.settings == %{}
    end

    test "update_preset/2 with invalid data returns error changeset" do
      preset = preset_fixture()
      assert {:error, %Ecto.Changeset{}} = Storage.update_preset(preset, @invalid_attrs)
      assert preset == Storage.get_preset!(preset.id)
    end

    test "delete_preset/1 deletes the preset" do
      preset = preset_fixture()
      assert {:ok, %Preset{}} = Storage.delete_preset(preset)
      assert_raise Ecto.NoResultsError, fn -> Storage.get_preset!(preset.id) end
    end

    test "change_preset/1 returns a preset changeset" do
      preset = preset_fixture()
      assert %Ecto.Changeset{} = Storage.change_preset(preset)
    end
  end
end
