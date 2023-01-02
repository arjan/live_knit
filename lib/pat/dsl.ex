defmodule Pat.Dsl do
  defmodule Allowlist do
    use Dune.Allowlist, extend: Dune.Allowlist.Default

    allow(Pat, :all)
  end

  @empty Pat.new(10, 10)

  def eval(str) do
    case Dune.eval_string(str, allowlist: Allowlist) do
      %Dune.Success{value: %Pat{} = pat} = result ->
        {:ok, pat}

      %Dune.Success{} = result ->
        {:ok, @empty}

      %Dune.Failure{message: message} ->
        {:error, message}
    end
  end
end
