defmodule Tux do
  require IEx

  defmodule Rental, do: defstruct rate: nil, moved_in_at: nil, closed_on: nil, month_list: []

  def process(unit_length, unit_width, city) do
    time_start = :erlang.monotonic_time

    {:ok, db} = Tux.DB.initialize("cs_prod")
    {:ok, facility_ids } = Tux.DB.fetch_facilities(db, city)
    {:ok, unit_ids} = Tux.DB.fetch_units(db, facility_ids, unit_length, unit_width)

    {:ok, rental_results, num_rentals} = Tux.DB.fetch_rentals(db, facility_ids, unit_ids)

    Tux.Parallel.process(rental_results, num_rentals, time_start)
  end

  def process(unit_length, unit_width) do
    time_start = :erlang.monotonic_time

    # Probably should toss down into a single method
    {:ok, db} = Tux.DB.initialize("cs_prod")
    {:ok, unit_ids} = Tux.DB.fetch_units(db, unit_length, unit_width)
    {:ok, rental_results, num_rentals} = Tux.DB.fetch_rentals(db, unit_ids)

    Tux.Parallel.process(rental_results, num_rentals, time_start)
  end

  def popular_cities(unit_length, unit_width) do
    {:ok, db} = Tux.DB.initialize("cs_prod")
    cities = Tux.DB.fetch_popular_cities(db, unit_length, unit_width)

    keys = [:city, :state, :occurences]

    attrs = Enum.map(cities, fn city -> Enum.zip(keys, city) |> Enum.into(%{}) end)
    Enum.zip(Enum.to_list(1..10), attrs) |> Enum.map(fn {id, city} ->
      %{ id: id, type: "city-datas", attributes: city }
    end)
  end

  # Move me
  def month_array do
    [:january, :february, :march, :april, :may, :june, :july, :august, :september, :october, :november, :december]
  end
end
