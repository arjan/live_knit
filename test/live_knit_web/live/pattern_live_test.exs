defmodule LiveKnitWeb.PatternLiveTest do
  use LiveKnitWeb.ConnCase

  import Phoenix.LiveViewTest
  import LiveKnit.StorageFixtures

  @create_attrs %{code: "some code", title: "some title"}
  @update_attrs %{code: "some updated code", title: "some updated title"}
  @invalid_attrs %{code: nil, title: nil}

  defp create_pattern(_) do
    pattern = pattern_fixture()
    %{pattern: pattern}
  end

  describe "Index" do
    setup [:create_pattern]

    test "lists all patterns", %{conn: conn, pattern: pattern} do
      {:ok, _index_live, html} = live(conn, Routes.pattern_index_path(conn, :index))

      assert html =~ "Listing Patterns"
      assert html =~ pattern.code
    end

    test "saves new pattern", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.pattern_index_path(conn, :index))

      assert index_live |> element("a", "New Pattern") |> render_click() =~
               "New Pattern"

      assert_patch(index_live, Routes.pattern_index_path(conn, :new))

      assert index_live
             |> form("#pattern-form", pattern: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#pattern-form", pattern: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.pattern_index_path(conn, :index))

      assert html =~ "Pattern created successfully"
      assert html =~ "some code"
    end

    test "updates pattern in listing", %{conn: conn, pattern: pattern} do
      {:ok, index_live, _html} = live(conn, Routes.pattern_index_path(conn, :index))

      assert index_live |> element("#pattern-#{pattern.id} a", "Edit") |> render_click() =~
               "Edit Pattern"

      assert_patch(index_live, Routes.pattern_index_path(conn, :edit, pattern))

      assert index_live
             |> form("#pattern-form", pattern: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#pattern-form", pattern: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.pattern_index_path(conn, :index))

      assert html =~ "Pattern updated successfully"
      assert html =~ "some updated code"
    end

    test "deletes pattern in listing", %{conn: conn, pattern: pattern} do
      {:ok, index_live, _html} = live(conn, Routes.pattern_index_path(conn, :index))

      assert index_live |> element("#pattern-#{pattern.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#pattern-#{pattern.id}")
    end
  end

  describe "Show" do
    setup [:create_pattern]

    test "displays pattern", %{conn: conn, pattern: pattern} do
      {:ok, _show_live, html} = live(conn, Routes.pattern_show_path(conn, :show, pattern))

      assert html =~ "Show Pattern"
      assert html =~ pattern.code
    end

    test "updates pattern within modal", %{conn: conn, pattern: pattern} do
      {:ok, show_live, _html} = live(conn, Routes.pattern_show_path(conn, :show, pattern))

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Pattern"

      assert_patch(show_live, Routes.pattern_show_path(conn, :edit, pattern))

      assert show_live
             |> form("#pattern-form", pattern: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#pattern-form", pattern: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.pattern_show_path(conn, :show, pattern))

      assert html =~ "Pattern updated successfully"
      assert html =~ "some updated code"
    end
  end
end
