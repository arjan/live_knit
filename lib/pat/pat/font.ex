defmodule Pat.Font do
  @fonts %{
    :sigi5b => "sigi-pixel-font/Sigi-5px-Bold.json",
    :sigi5cb => "sigi-pixel-font/Sigi-5px-Condensed-Bold.json",
    :sigi5c => "sigi-pixel-font/Sigi-5px-Condensed-Regular.json",
    :sigi5 => "sigi-pixel-font/Sigi-5px-Regular.json",
    :sigi7b => "sigi-pixel-font/Sigi-7px-Bold.json",
    :sigi7 => "sigi-pixel-font/Sigi-7px-Regular.json"
  }

  defstruct name: nil, height: nil, glyphs: %{}, stride: nil

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

    file = Application.app_dir(:live_knit, ["priv", "fonts", "#{name}.json"])

    unless File.exists?(file) do
      raise RuntimeError, "Font not found: #{name}"
    end

    data =
      file
      |> File.read!()
      |> Jason.decode!()

    for glyph <- data["glyphs"],
        reduce: %Font{name: data["name"], height: data["height"], stride: stride} do
      font ->
        canvas =
          case glyph do
            %{"coords" => coords} ->
              for [x, y] <- coords, reduce: Pat.new(glyph["width"], font.height, bg) do
                canvas -> canvas |> Pat.set(x, y, fg)
              end

            %{"data" => rows, "width" => width} ->
              %Pat{data: to_string(Enum.reverse(rows)), w: width, h: font.height} |> Pat.invert()
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

  def render(%Font{} = font, %Pat{} = canvas, text, x, y) do
    for g <- String.graphemes(text), reduce: {x, canvas} do
      {x, canvas} ->
        c = glyph(font, g)
        {x + c.w + font.stride, Pat.set(canvas, x, y, c)}
    end
    |> elem(1)
  end
end
