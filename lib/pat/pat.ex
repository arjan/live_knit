defmodule Pat do
  defmacro __using__(_) do
  end

  defmodule Canvas do
    defstruct w: 0, h: 0, data: ""
    alias __MODULE__, as: Canvas

    def new(w, h, pixel \\ "0") when is_binary(pixel) and byte_size(pixel) == 1 do
      data = to_string(for _ <- 1..w, _ <- 1..h, do: pixel)
      %Canvas{w: w, h: h, data: data}
    end

    def set(%Canvas{} = canvas, x, y, pixel) when is_binary(pixel) do
      o = offset(canvas, x, y)

      if o >= 0 and o < byte_size(canvas.data) do
        {head, rest} = String.split_at(canvas.data, offset(canvas, x, y))

        l = byte_size(pixel)
        max_w = min(l, canvas.w - x)
        {_ignore, tail} = String.split_at(rest, max_w)
        {pixel, _ignore} = String.split_at(pixel, max_w)
        %Canvas{canvas | data: to_string([head, pixel, tail])}
      else
        canvas
      end
    end

    def set(%Canvas{} = canvas, x, y, %Canvas{} = source) do
      source_rows = rows(source)

      for dy <- 0..(source.h - 1), reduce: canvas do
        canvas -> set(canvas, x, y + dy, Enum.at(source_rows, dy))
      end
    end

    defp offset(%Canvas{} = canvas, x, y), do: canvas.w * y + x

    def rows(%Canvas{} = canvas) do
      for y <- 0..(canvas.h - 1) do
        String.slice(canvas.data, offset(canvas, 0, y), canvas.w)
      end
    end

    def print(%Canvas{} = canvas) do
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
      %Canvas{canvas | data: data}
    end

    def transform(canvas, :vflip) do
      data = rows(canvas) |> Enum.map(&String.reverse/1) |> to_string
      %Canvas{canvas | data: data}
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
        Canvas.rows(canvas)
        |> Enum.map(&String.split(&1, "", trim: true))
        |> transpose()
        |> Enum.reverse()
        |> to_string()

      %Canvas{canvas | w: canvas.h, h: canvas.w, data: data}
    end

    defp transpose([[] | _]), do: []
    defp transpose(m), do: [Enum.map(m, &hd/1) | transpose(Enum.map(m, &tl/1))]
  end

  defmodule Font do
    @fonts %{
      :sigi5b => "sigi-pixel-font/Sigi-5px-Bold.json",
      :sigi5cb => "sigi-pixel-font/Sigi-5px-Condensed-Bold.json",
      :sigi5c => "sigi-pixel-font/Sigi-5px-Condensed-Regular.json",
      :sigi5 => "sigi-pixel-font/Sigi-5px-Regular.json",
      :sigi7b => "sigi-pixel-font/Sigi-7px-Bold.json",
      :sigi7 => "sigi-pixel-font/Sigi-7px-Regular.json"
    }

    defstruct name: nil, height: nil, glyphs: %{}, stride: nil

    alias Pat.Canvas
    alias __MODULE__, as: Font

    @doc """
    Load font

    Options:
    - stride: the spacing between letters in pixels
    - fg: foreground character for canvas
    - bg: background character for canvas
    """

    def load(name, opts \\ []) when is_atom(name) do
      fg = Keyword.get(opts, :fg, "1")
      bg = Keyword.get(opts, :bg, "0")
      stride = Keyword.get(opts, :stride, 1)

      font = @fonts[name]

      if font == nil do
        raise RuntimeError, "Font not found: #{name}"
      end

      data =
        Application.app_dir(:live_knit, "priv/" <> font)
        |> File.read!()
        |> Jason.decode!()

      for glyph <- data["glyphs"],
          reduce: %Font{name: data["name"], height: data["height"], stride: stride} do
        font ->
          canvas =
            for [x, y] <- glyph["coords"], reduce: Canvas.new(glyph["width"], font.height, bg) do
              canvas -> canvas |> Canvas.set(x, y, fg)
            end

          glyphs = Map.put(font.glyphs, glyph["name"], canvas)
          %Font{font | glyphs: glyphs}
      end
    end

    defp glyph(font, g) do
      u = Unidecode.decode(g)
      variants = [g, String.upcase(g), String.downcase(g), String.upcase(u), String.downcase(u)]

      for v <- variants, reduce: nil do
        g -> g || font.glyphs[v]
      end || font.glyphs["?"] ||
        raise(RuntimeError, "Missing grapheme '#{g}' in font #{font.name}")
    end

    def measure(%Font{} = font, string) do
      w =
        for g <- String.graphemes(string) do
          glyph(font, g).w
        end
        |> Enum.intersperse(font.stride)
        |> Enum.reduce(0, &(&1 + &2))

      {w, font.height}
    end

    def render(%Font{} = font, %Canvas{} = canvas, text, x, y) do
      for g <- String.graphemes(text), reduce: {x, canvas} do
        {x, canvas} ->
          c = glyph(font, g)
          {x + c.w + font.stride, Canvas.set(canvas, x, y, c)}
      end
      |> elem(1)
    end
  end
end
