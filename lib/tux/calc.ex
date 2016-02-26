defmodule Tux.Calc do
  alias Tux.Rental
  alias Postgrex.Timestamp

  ############
  # Formatting
  ############
  def format_and_filter_rentals(rentals) do
    rentals
    |> Enum.map(&(Enum.zip([:rate, :moved_in_at, :closed_on], &1)))
    |> Enum.map(&Enum.into(&1, %{}))
    |> Enum.map(fn (r) -> %Rental{rate: r.rate, moved_in_at: r.moved_in_at, closed_on: r.closed_on} end)
    |> Enum.filter(fn (r) -> r.moved_in_at != nil  && r.rate != nil  end)
  end

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
    # grab today's year and month
    { {year, month, _}, _ } = :os.timestamp |> :calendar.now_to_datetime
    compute_month_list(moved_in_at, %Timestamp{year: year, month: month})
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
        Map.put(inner_month_map, month, inner_month_map[month] ++ [rental.rate])
      end)
    end)
  end

  defp base_month_map do
    %{
      1  => [], 2  => [], 3  => [], 4  => [], 5  => [], 6  => [],
      7  => [], 8  => [], 9  => [], 10 => [], 11 => [], 12 => []
    }
  end


  ####################
  # Reduce to Avg List
  ####################
  def reduce_to_averages_list(month_map) do
    Enum.reduce(1..12, [], fn month, acc ->
      acc ++ [Tux.Calc.calculate_average(Dict.get(month_map, month))]
    end)
  end

  # Calculate Monthly Average Task
  def calculate_monthly_average(rentals) do
    rentals
    |> Enum.map(&compute_month_list(&1))
    |> reduce_to_month_map
    |> reduce_to_averages_list
    |> Enum.map(&(Decimal.to_string(&1) |> Float.parse |> elem(0)))
  end

  #####################
  # Average Calculation
  #####################
  def calculate_average(rates), do:
    calculate_average(rates, Enum.count(rates))

  def calculate_average(_rates, 0), do: Decimal.new(0.0)

  def calculate_average(rates, num_rentals) do
    top = sum_rates(rates)
    bottom = Decimal.new(num_rentals)
    Decimal.div(top,bottom) |> Decimal.round(2)
  end

  def sum_rates(rates), do:
    Enum.reduce(rates, Decimal.new(0.0), fn (i, acc) -> Decimal.add(i, acc) end)

  # man there has to be a better way to init these
  def base_tuple_list do
    [{Decimal.new(0.0), 0}, {Decimal.new(0.0), 0}, {Decimal.new(0.0), 0}, {Decimal.new(0.0), 0},
     {Decimal.new(0.0), 0}, {Decimal.new(0.0), 0}, {Decimal.new(0.0), 0}, {Decimal.new(0.0), 0},
     {Decimal.new(0.0), 0}, {Decimal.new(0.0), 0}, {Decimal.new(0.0), 0}, {Decimal.new(0.0), 0}]
  end
end
