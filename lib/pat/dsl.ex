defmodule Pat.Dsl do
  defmodule Allowlist do
    use Dune.Allowlist, extend: Dune.Allowlist.Default

    allow(Pat, :all)
    allow(Pat.Font, :all)
  end

  @empty Pat.new(10, 10)

  def eval(str) do
    import Pat

    try do
      case Code.eval_string(str, [], __ENV__) do
        {%Pat{} = pat, _} ->
          {:ok, pat}

        {_other, _} ->
          {:ok, @empty}
      end
    catch
      _, m ->
        {:error, inspect(m)}
    end
  end
end
