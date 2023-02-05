defmodule Pat.Dsl do
  defmodule Allowlist do
    use Dune.Allowlist, extend: Dune.Allowlist.Default

    allow(Pat, :all)
    allow(Pat.Font, :all)
  end

  @empty Pat.new(10, 10)

  def eval(str) do
    case Dune.eval_string(str, max_reductions: 1_000_000, memory: 10_000_000) do
      %Dune.Success{value: %Pat{} = pat} ->
        {:ok, pat}

      %Dune.Success{} ->
        {:ok, @empty}

      %Dune.Failure{message: message} ->
        {:error, message}
    end
  end
end
