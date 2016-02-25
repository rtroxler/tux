defmodule Tux.Calc do
  alias Tux.Rental
  alias Postgrex.Timestamp

  def compute_month_list(%Timestamp{year: year, month: month1},
                           %Timestamp{year: year, month: month2}), do:
    Enum.to_list month1..month2

  def compute_month_list(moved_in_at, closed_on) do
    num_full_years = closed_on.year - moved_in_at.year - 1
    Enum.to_list(moved_in_at.month..12)
      ++ build_full_years(num_full_years)
      ++ Enum.to_list(1..closed_on.month)
    |> List.flatten
  end

  defp build_full_years(0), do: []
  defp build_full_years(num_years) do
    for n <- 1..num_years, do: Enum.to_list(1..12)
    |> List.flatten
  end

  def calculate_average(rates, num_rentals) do
    Decimal.div(
      Enum.reduce(rates, Decimal.new(0.0), fn (i, acc) -> Decimal.add(i, acc) end),
      Decimal.new(num_rentals)
    ) |> Decimal.round(2)
  end
end
