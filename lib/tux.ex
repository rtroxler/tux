defmodule Tux do

  defmodule Rental, do: defstruct rate: nil, moved_in_at: nil, closed_on: nil, month_list: []

  # This is all gross as shit. #YOLO swag hackathon code
  def process(unit_length, unit_width, city) do
    {:ok, db} = Tux.DB.initialize("cs_prod")

    # Stick this shit somewhere too
    {:ok, facility_ids } = Tux.DB.fetch_facilities(db, city)
    {:ok, unit_ids} = Tux.DB.fetch_units(db, facility_ids, unit_length, unit_width)

    {:ok, rental_results, num_rentals} = Tux.DB.fetch_rentals(db, facility_ids, unit_ids)

    average_per_month = rental_results
    |> format_and_filter_rentals
    |> Tux.Calc.calculate_monthly_average # chunk this and perform in parallel, probably faster

    # Want to some how add processing time.. not as critical though
    Enum.zip(month_array, average_per_month)
    |> Enum.into(Map.new)
    |> Map.put("num-rentals-processed", num_rentals)
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

  defp format_and_filter_rentals(rentals) do
    rentals
    |> Enum.map(&(Enum.zip([:rate, :moved_in_at, :closed_on], &1)))
    |> Enum.map(&Enum.into(&1, %{}))
    |> Enum.map(fn (r) -> %Rental{rate: r.rate, moved_in_at: r.moved_in_at, closed_on: r.closed_on} end)
    |> Enum.filter(fn (r) -> r.moved_in_at != nil  && r.rate != nil  end)
  end

  defp month_array do
    [:january, :february, :march, :april, :may, :june, :july, :august, :september, :october, :november, :december]
  end
end
