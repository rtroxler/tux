defmodule Tux do

  defmodule Rental, do: defstruct rate: nil, moved_in_at: nil, closed_on: nil, month_list: []

  # This is all gross as shit. #YOLO swag hackathon code
  def process(unit_length, unit_width, city) do
    {:ok, db} = Tux.DB.initialize("cs_prod")

    # Stick this shit somewhere too
    {:ok, facility_ids } = Tux.DB.fetch_facilities(db, city)
    {:ok, unit_ids} = Tux.DB.fetch_units(db, facility_ids, unit_length, unit_width)
    {:ok, rates, num_rentals} = Tux.DB.fetch_rental_rates(db, facility_ids, unit_ids)

    # Need to have a if rates empty don't do this check..
    average_rate = rates
    |> filter_all_the_shit
    |> Tux.Calc.calculate_average(num_rentals)

    IO.puts "Average rate for a #{unit_length}x#{unit_width} in #{city} is $#{average_rate}. (#{num_rentals} rentals)"

    # playing with stuff
    {:ok, rental_results} = Tux.DB.fetch_rentals(db, facility_ids, unit_ids)

    rentals = rental_results
    |> format_rentals
    |> Enum.filter(fn (r) -> r.moved_in_at != nil end)
    |> Enum.map(&Tux.Calc.compute_month_list(&1))
    |> Tux.Calc.reduce_to_month_map
    require IEx
    IEx.pry
  end

  def popular_cities(unit_length, unit_width) do
    {:ok, db} = Tux.DB.initialize("cs_prod")
    Tux.DB.fetch_popular_cities(db, unit_length, unit_width)
  end

  defp filter_all_the_shit(rates) do
    rates
    |> Enum.filter(&(&1 != nil))
    |> Enum.filter(&(&1 != Decimal.new(-1.0))) # Fuckin' -1 rates ( I Don't think this works )
  end

  defp format_rentals(rentals) do
    rentals
    |> Enum.map(&(Enum.zip([:rate, :moved_in_at, :closed_on], &1)))
    |> Enum.map(&Enum.into(&1, %{}))
    |> Enum.map(fn (r) -> %Rental{rate: r.rate, moved_in_at: r.moved_in_at, closed_on: r.closed_on} end)
  end

end
