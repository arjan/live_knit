defmodule LiveKnit.StorageTest do
  use LiveKnit.DataCase

  alias LiveKnit.Storage

  describe "patterns" do
    alias LiveKnit.Storage.Pattern

    import LiveKnit.StorageFixtures

    @invalid_attrs %{code: nil, title: nil}

    test "list_patterns/0 returns all patterns" do
      pattern = pattern_fixture()
      assert [_ | _] = Storage.list_patterns()
    end

    test "get_pattern!/1 returns the pattern with given id" do
      pattern = pattern_fixture()
      assert Storage.get_pattern!(pattern.id) == pattern
    end

    test "create_pattern/1 with valid data creates a pattern" do
      valid_attrs = %{code: "some code", title: "some title"}

      assert {:ok, %Pattern{} = pattern} = Storage.create_pattern(valid_attrs)
      assert pattern.code == "some code"
      assert pattern.title == "some title"
    end

    test "create_pattern/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Storage.create_pattern(@invalid_attrs)
    end

    test "update_pattern/2 with valid data updates the pattern" do
      pattern = pattern_fixture()
      update_attrs = %{code: "some updated code", title: "some updated title"}

      assert {:ok, %Pattern{} = pattern} = Storage.update_pattern(pattern, update_attrs)
      assert pattern.code == "some updated code"
      assert pattern.title == "some updated title"
    end

    test "update_pattern/2 with invalid data returns error changeset" do
      pattern = pattern_fixture()
      assert {:error, %Ecto.Changeset{}} = Storage.update_pattern(pattern, @invalid_attrs)
      assert pattern == Storage.get_pattern!(pattern.id)
    end

    test "delete_pattern/1 deletes the pattern" do
      pattern = pattern_fixture()
      assert {:ok, %Pattern{}} = Storage.delete_pattern(pattern)
      assert_raise Ecto.NoResultsError, fn -> Storage.get_pattern!(pattern.id) end
    end

    test "change_pattern/1 returns a pattern changeset" do
      pattern = pattern_fixture()
      assert %Ecto.Changeset{} = Storage.change_pattern(pattern)
    end
  end
end
