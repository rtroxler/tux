defmodule Tux.Calc do
  alias Tux.Rental
  alias Postgrex.Timestamp

  ####################
  # Compute Month List
  ####################
  def compute_month_list(rental) do
    %Rental{ rental | month_list: compute_month_list(rental.moved_in_at, rental.closed_on) }
  end

  def compute_month_list(%Timestamp{year: year, month: month1},
                           %Timestamp{year: year, month: month2}), do:
    Enum.to_list month1..month2

  def compute_month_list(moved_in_at, nil) do
    # TODO: me
  end

  def compute_month_list(moved_in_at, closed_on) do
    num_full_years = closed_on.year - moved_in_at.year - 1
    Enum.to_list(moved_in_at.month..12)
      ++ build_full_years(num_full_years)
      ++ Enum.to_list(1..closed_on.month)
    |> List.flatten
  end


  defp build_full_years(0), do: []
  defp build_full_years(num_years) do
    for _ <- 1..num_years, do: Enum.to_list(1..12)
    |> List.flatten
  end

  ####################
  # Compute Month Map
  ####################
  def reduce_to_month_map(rentals) do
    Enum.reduce(rentals, base_month_map, fn (rental, month_map) ->
      Enum.reduce(rental.month_list, month_map, fn (month, inner_month_map) ->
        Map.put(inner_month_map, month, month_map[month] ++ [rental.rate])
      end)
    end)
  end

  defp base_month_map do
    %{
      1  => [], 2  => [], 3  => [], 4  => [], 5  => [], 6  => [],
      7  => [], 8  => [], 9  => [], 10 => [], 11 => [], 12 => []
    }
  end


  #####################
  # Average Calculation
  #####################
  def calculate_average(rates, num_rentals) do
    Decimal.div(
      Enum.reduce(rates, Decimal.new(0.0), fn (i, acc) -> Decimal.add(i, acc) end),
      Decimal.new(num_rentals)
    ) |> Decimal.round(2)
  end
end
