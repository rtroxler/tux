defmodule Benchmark do

  def measure(function) do
    r = function
    |> :timer.tc
    |> elem(0)
    |> Kernel./(1_000_000)
  end
end
