defmodule Pat do
  defstruct w: 0, h: 0, data: ""

  alias Pat.Font

  def from_string(string) do
    rows = String.split(string, "\n")
    w = String.length(List.first(rows))
    h = Enum.count(rows)
    data = to_string(rows)

    if w * h != String.length(data) do
      raise RuntimeError, "Non-rectangular pattern in Pat.from_string"
    end

    %Pat{data: data, w: w, h: h}
  end

  @doc """
  Overlay one pat on top of the other, clipping within the dimensions of the target pat.

  A resolve function can be given to customize the overlay algorithm
  on a line-by-line basis. For each "conflict, where the target would
  be overwritten by the source, the overlay function is called.
  """
  def overlay(target, source, x, y, resolve_fn \\ nil) do
    tr = rows(target)

    pre = Enum.slice(tr, 0, y)
    post = Enum.slice(tr, y + source.h, target.h)

    tr =
      if y > 0 do
        Enum.slice(tr, y, y + source.h - 1)
      else
        Enum.slice(tr, 0, source.h)
      end

    data =
      [
        pre,
        for {target_row, source_row} <- Enum.zip(tr, rows(source)) do
          [
            if x > 0 do
              String.slice(target_row, 0..(x - 1))
            else
              []
            end,
            if target.w - x > 0 do
              {source, target} =
                if x >= 0 do
                  {String.slice(source_row, 0..(target.w - x - 1)),
                   String.slice(target_row, x..target.w)}
                else
                  {String.slice(source_row, -x..source.w),
                   String.slice(target_row, 0..(source.w + x))}
                end

              if resolve_fn do
                resolve_fn.(target, source) |> String.slice(0..(String.length(target) - 1))
              else
                source
              end
            else
              []
            end,
            String.slice(target_row, (x + source.w)..target.w)
          ]
        end,
        post
      ]
      |> to_string()

    if target.w * target.h != String.length(data) do
      raise RuntimeError, "Non-rectangular pattern in Pat.from_string"
    end

    %{target | data: data}
  end

  def new(w, h, pixel \\ "0") when is_binary(pixel) and byte_size(pixel) == 1 do
    data = to_string(for _ <- 1..w, _ <- 1..h, do: pixel)
    %Pat{w: w, h: h, data: data}
  end

  def new_text(text, opts \\ []) do
    font_name = Keyword.get(opts, :font, :sigi5b)

    font =
      Font.load(font_name, fg: opts[:fg] || "X", bg: opts[:bg] || " ", stride: opts[:stride] || 2)

    {w, h} = Font.measure(font, text)

    target = Pat.new(w, h, " ")
    Font.render(font, target, text, 0, 0)
  end

  def repeat_h(%Pat{} = pat, times) do
    data =
      for row <- rows(pat), _ <- 1..times do
        row
      end
      |> to_string()

    %{pat | data: data, w: times * pat.w}
  end

  def repeat_v(%Pat{} = pat, times) do
    data =
      for _ <- 1..times do
        pat.data
      end
      |> to_string()

    %{pat | data: data, h: times * pat.h}
  end

  def set(%Pat{} = canvas, x, y, pixel) when is_binary(pixel) do
    o = offset(canvas, x, y)

    if o >= 0 and o < byte_size(canvas.data) do
      {head, rest} = String.split_at(canvas.data, offset(canvas, x, y))

      l = byte_size(pixel)
      max_w = min(l, canvas.w - x)
      {_ignore, tail} = String.split_at(rest, max_w)
      {pixel, _ignore} = String.split_at(pixel, max_w)
      %Pat{canvas | data: to_string([head, pixel, tail])}
    else
      canvas
    end
  end

  def set(%Pat{} = canvas, x, y, %Pat{} = source) do
    source_rows = rows(source)

    for dy <- 0..(source.h - 1), reduce: canvas do
      canvas -> set(canvas, x, y + dy, Enum.at(source_rows, dy))
    end
  end

  defp offset(%Pat{} = canvas, x, y), do: canvas.w * y + x

  def rows(%Pat{} = canvas) do
    for y <- 0..(canvas.h - 1) do
      String.slice(canvas.data, offset(canvas, 0, y), canvas.w)
    end
  end

  def print(%Pat{} = canvas) do
    for row <- rows(canvas) do
      IO.puts(row)
    end

    canvas
  end

  def transform(canvas, operations) when is_list(operations) do
    Enum.reduce(operations, canvas, &transform(&2, &1))
  end

  def transform(canvas, :hflip) do
    data = rows(canvas) |> Enum.reverse() |> to_string
    %Pat{canvas | data: data}
  end

  def transform(canvas, :vflip) do
    data = rows(canvas) |> Enum.map(&String.reverse/1) |> to_string
    %Pat{canvas | data: data}
  end

  def transform(canvas, :r180) do
    transform(canvas, [:hflip, :vflip])
  end

  def transform(canvas, :rcw) do
    transform(canvas, [:rccw, :r180])
  end

  def transform(canvas, :rccw) do
    # rotate counter clock wise
    data =
      rows(canvas)
      |> Enum.map(&String.split(&1, "", trim: true))
      |> transpose()
      |> Enum.reverse()
      |> to_string()

    %Pat{canvas | w: canvas.h, h: canvas.w, data: data}
  end

  defp transpose([[] | _]), do: []
  defp transpose(m), do: [Enum.map(m, &hd/1) | transpose(Enum.map(m, &tl/1))]

  def border(target, source, opts \\ []) do
    flip = Keyword.get(opts, :flip, true)

    target
    |> Pat.border_left(source)
    |> Pat.border_right(if flip, do: transform(source, :hflip), else: source)
    |> Pat.border_top(source)
    |> Pat.border_bottom(if flip, do: transform(source, :vflip), else: source)
  end

  def border_left(target, source) do
    times = ceil(target.h / source.h)
    source = source |> repeat_v(times)

    target |> overlay(source, 0, 0)
  end

  def border_right(target, source) do
    times = ceil(target.h / source.h)
    source = source |> repeat_v(times)

    target |> overlay(source, target.w - source.w, 0)
  end

  def border_top(target, source) do
    times = ceil(target.w / source.w)
    source = source |> repeat_h(times)

    target |> overlay(source, 0, 0)
  end

  def border_bottom(target, source) do
    times = ceil(target.w / source.w)
    source = source |> repeat_h(times)

    target |> overlay(source, 0, target.h - source.h)
  end

  defimpl String.Chars do
    def to_string(pat) do
      Pat.rows(pat)
      |> Enum.intersperse("\n")
      |> IO.iodata_to_binary()
    end
  end
end
