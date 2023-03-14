defmodule Pat do
  @derive Jason.Encoder
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

  def new(w, h, pixel \\ "0") when is_binary(pixel) and byte_size(pixel) == 1 do
    data = to_string(for _ <- 1..w, _ <- 1..h, do: pixel)
    %Pat{w: w, h: h, data: data}
  end

  def new_text(text, opts \\ []) do
    font_name = Keyword.get(opts, :font, :sigi5b)

    bg = opts[:bg] || "1"
    font = Font.load(font_name, fg: opts[:fg] || "0", bg: bg, stride: opts[:stride])

    pats =
      for line <- String.split(text, "\n") do
        {w, h} = Font.measure(font, line)

        target = Pat.new(w, h, "1")
        Font.render(font, target, line, 0, 0)
      end

    w = Enum.reduce(pats, 0, &max(&1.w, &2))

    pats
    |> Enum.map(fn pat ->
      if pat.w < w do
        d = w - pat.w

        case opts[:align] do
          :center ->
            d1 = div(d, 2)
            d2 = d - d1

            pat
            |> pad_left(d1, bg)
            |> pad_right(d2, bg)

          :right ->
            pat |> pad_left(d, bg)

          _ ->
            pat |> pad_right(d, bg)
        end
      else
        pat
      end
    end)
    |> Enum.intersperse(Pat.new(w, Keyword.get(opts, :line_pad, 1), bg))
    |> concat_v()
  end

  @doc """
  Overlay one pat on top of the other, clipping within the dimensions of the target pat.

  A resolve function can be given to customize the overlay algorithm
  on a line-by-line basis. For each "conflict, where the target would
  be overwritten by the source, the overlay function is called.

  The position can be either an `{x, y}` tuple or one of `:left`,
  `:right`, `:top`, `:bottom`, `:top_left`, `:top_right`,
  `:bottom_left`, `:bottom_right`.
  """
  def overlay(target, source, pos, effect \\ nil) do
    resolve_fn = build_effect(effect)
    {x, y} = overlay_pos(pos, target, source)
    tr = rows(target)

    {pre, tr, post} =
      if y >= 0 do
        {
          Enum.slice(tr, 0, y),
          Enum.slice(tr, y, y + source.h),
          Enum.slice(tr, y + source.h, target.h)
        }
      else
        {[], Enum.slice(tr, 0, source.h), []}
      end

    source_rows =
      if y >= 0 do
        rows(source)
      else
        Enum.slice(rows(source), -y, Enum.count(tr))
      end

    data =
      [
        pre,
        for {target_row, source_row} <- Enum.zip(tr, source_rows) do
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
                  t = String.slice(target_row, 0..(source.w + x))

                  {String.slice(source_row, -x..source.w)
                   |> String.slice(0..(String.length(t) - 1)), t}
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
      raise RuntimeError, "Non-rectangular pattern in Pat.overlay"
    end

    %{target | data: data}
  end

  defp build_effect(nil), do: nil
  defp build_effect(f) when is_function(f, 2), do: f

  defp build_effect(:xor) do
    fn target, source ->
      [target |> String.split("", trim: true), source |> String.split("", trim: true)]
      |> Enum.zip()
      |> Enum.map(fn
        {"1", "0"} -> "0"
        {"0", "1"} -> "0"
        {"1", "1"} -> "1"
        {"0", "0"} -> "1"
      end)
      |> to_string()
    end
  end

  defp overlay_pos(:center, target, source),
    do: {div(target.w - source.w, 2), div(target.h - source.h, 2)}

  defp overlay_pos(:top, target, source),
    do: {div(target.w - source.w, 2), 0}

  defp overlay_pos(:bottom, target, source),
    do: {div(target.w - source.w, 2), target.h - source.h}

  defp overlay_pos(:left, target, source),
    do: {0, div(target.h - source.h, 2)}

  defp overlay_pos(:right, target, source),
    do: {target.w - source.w, div(target.h - source.h, 2)}

  defp overlay_pos(:top_left, _target, _source), do: {0, 0}
  defp overlay_pos(:top_right, target, source), do: {target.w - source.w, 0}
  defp overlay_pos(:bottom_left, target, source), do: {0, target.h - source.h}
  defp overlay_pos(:bottom_right, target, source), do: {target.w - source.w, target.h - source.h}

  defp overlay_pos({x, y}, _target, _source), do: {x, y}

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
    source = coerce_source(source)
    flip = Keyword.get(opts, :flip, true)

    target
    |> Pat.border_left(source)
    |> Pat.border_right(if flip, do: transform(source, :hflip), else: source)
    |> Pat.border_top(source)
    |> Pat.border_bottom(if flip, do: transform(source, :vflip), else: source)
  end

  def border_left(target, source) do
    source = coerce_source(source)
    times = ceil(target.h / source.h)
    source = source |> repeat_v(times)

    target |> overlay(source, {0, 0})
  end

  def border_right(target, source) do
    source = coerce_source(source)
    times = ceil(target.h / source.h)
    source = source |> repeat_v(times)

    target |> overlay(source, {target.w - source.w, 0})
  end

  def border_top(target, source) do
    source = coerce_source(source)
    times = ceil(target.w / source.w)
    source = source |> repeat_h(times)

    target |> overlay(source, {0, 0})
  end

  def border_bottom(target, source) do
    source = coerce_source(source)
    times = ceil(target.w / source.w)
    source = source |> repeat_h(times)

    target |> overlay(source, {0, target.h - source.h})
  end

  def concat_h([first | rest] = all) do
    for pat <- rest do
      if pat.h != first.h do
        raise RuntimeError, "Pat.concat_h: height #{pat.h} != #{first.h}"
      end
    end

    [first_row | _] =
      pat_rows =
      Enum.map(all, &rows/1)
      |> transpose()

    data =
      pat_rows
      |> to_string()

    %Pat{data: data, h: first.h, w: String.length(to_string(first_row))}
  end

  def concat_h(target, source) do
    concat_h([target, source])
  end

  def concat_v([first | rest] = all) do
    for pat <- rest do
      if pat.w != first.w do
        raise RuntimeError, "Pat.concat_v: width #{pat.w} != #{first.w}"
      end
    end

    h = Enum.reduce(all, 0, &(&1.h + &2))
    data = Enum.map(all, &rows/1) |> to_string()

    %Pat{data: data, h: h, w: first.w}
  end

  def concat_v(target, source) do
    concat_v([target, source])
  end

  def pad(%Pat{} = pat, amount, pixel \\ "0") do
    new(pat.w + 2 * amount, pat.h + 2 * amount, pixel) |> overlay(pat, {amount, amount})
  end

  def pad_top(%Pat{} = pat, amount, pixel \\ "0"), do: new(pat.w, amount, pixel) |> concat_v(pat)

  def pad_left(%Pat{} = pat, amount, pixel \\ "0"), do: new(amount, pat.h, pixel) |> concat_h(pat)

  def pad_bottom(%Pat{} = pat, amount, pixel \\ "0"),
    do: pat |> concat_v(new(pat.w, amount, pixel))

  def pad_right(%Pat{} = pat, amount, pixel \\ "0"),
    do: pat |> concat_h(new(amount, pat.h, pixel))

  def invert(%Pat{} = pat) do
    data = pat.data |> String.split("", trim: true) |> Enum.map(&inv/1) |> to_string()
    %{pat | data: data}
  end

  defp inv("1"), do: "0"
  defp inv("0"), do: "1"
  defp inv("X"), do: " "
  defp inv(" "), do: "X"

  def coerce_source("" <> source), do: from_string(source)
  def coerce_source(%Pat{} = source), do: source

  def stretch_v(%Pat{} = pat, fact) do
    rows = rows(pat) |> stretch_rows(fact)
    %{pat | data: to_string(rows), h: length(rows)}
  end

  def stretch_h(%Pat{} = pat, fact) do
    rows =
      rows(pat)
      |> Enum.map(&String.split(&1, "", trim: true))
      |> transpose()
      |> stretch_rows(fact)
      |> transpose()

    %{pat | data: to_string(rows), w: length(hd(rows))}
  end

  def stretch(%Pat{} = pat, fact) do
    pat |> stretch_v(fact) |> stretch_h(fact)
  end

  def double(%Pat{} = pat) do
    stretch(pat, 2)
  end

  defp stretch_rows(rows, fact) do
    fact_int = ceil(fact)

    all_rows = for r <- rows, _ <- 1..fact_int, do: r
    n_all = length(all_rows)

    to_remove = round(length(rows) * (fact_int - fact))

    if to_remove > 0 do
      stride = round(n_all / (to_remove + 1))

      remove_indices =
        Enum.reduce(1..(to_remove - 1), [n_all - stride], fn _, [i | _] = acc ->
          [i - stride | acc]
        end)
        |> Enum.reverse()

      Enum.reduce(remove_indices, all_rows, fn index, rows ->
        List.delete_at(rows, index)
      end)
    else
      all_rows
    end
  end

  def fit(%Pat{} = pat, w, h, opts \\ []) do
    bg = opts[:bg] || "1"
    w = w || pat.w
    h = h || pat.h
    pos = opts[:pos] || :center

    new(w, h, bg)
    |> overlay(pat, pos)
  end

  def fonts_showcase(opts \\ []) do
    Application.app_dir(:live_knit, ["priv", "fonts", "*.json"])
    |> Path.wildcard()
    |> Enum.map(fn filename ->
      font = Path.basename(filename) |> String.replace(".json", "")
      font_showcase(font, opts)
    end)
    |> concat_v()
  end

  def font_showcase(font, opts \\ []) do
    w = opts[:width] || 200
    p = opts[:p] || 1
    text = opts[:text] || "\nHello, Aloha world quick brown fox 1234567890"

    new_text("#{String.upcase(font)}#{text}", font: String.to_atom(to_string(font)))
    |> fit(w, nil, pos: :left)
    |> pad_bottom(p, "1")
  end

  ###

  defimpl String.Chars do
    def to_string(pat) do
      Pat.rows(pat)
      |> Enum.intersperse("\n")
      |> IO.iodata_to_binary()
    end
  end

  defimpl Phoenix.HTML.Safe do
    def to_iodata(pat) do
      Jason.encode!(pat)
    end
  end
end
