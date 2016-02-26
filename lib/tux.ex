defmodule Tux do

  defmodule Rental, do: defstruct rate: nil, moved_in_at: nil, closed_on: nil, month_list: []

  # This is all gross as shit. #YOLO swag hackathon code
  def process(unit_length, unit_width, city) do
    time_start = :erlang.monotonic_time

    {:ok, db} = Tux.DB.initialize("cs_prod")

    # Stick this shit somewhere too
    {:ok, facility_ids } = Tux.DB.fetch_facilities(db, city)
    {:ok, unit_ids} = Tux.DB.fetch_units(db, facility_ids, unit_length, unit_width)

    {:ok, rental_results, num_rentals} = Tux.DB.fetch_rentals(db, facility_ids, unit_ids)

    # TESTING NON PARALLEL
    # ( non parallel now sucks since I'm calculating it correctly)
    #non_parallel_average_per_month = rental_results
    #|> format_and_filter_rentals
    #|> Tux.Calc.calculate_monthly_average

    #IO.inspect Enum.zip(month_array, non_parallel_average_per_month)



    # TESTING PARALLEL
    processes = Tux.Parallel.calculate_optimal_process_size(num_rentals)
    chunk_size = div(num_rentals, processes)
    leftovers = rem(num_rentals, processes)

    average_per_month = Enum.chunk(rental_results, chunk_size) ++ [Enum.take(rental_results, -leftovers)]
    |> Tux.Parallel.parallel_crunch

    # this and above should be one method
    done = average_per_month
    |> Tux.Parallel.flatten_tuples_and_average # now this part is slow...
    |> Enum.map(&(Decimal.to_string(&1) |> Float.parse |> elem(0) |> Float.round(2)))

    time_end = :erlang.monotonic_time
    processing_time = (time_end - time_start) / 1000000000

    # format_result
    Enum.zip(month_array, done)
    |> Enum.into(Map.new)
    |> Map.put("num-rentals-processed", num_rentals)
    |> Map.put("processing-time", processing_time)
  end

  def process(unit_length, unit_width) do
    time_start = :erlang.monotonic_time

    {:ok, db} = Tux.DB.initialize("cs_prod")
    {:ok, unit_ids} = Tux.DB.fetch_units(db, unit_length, unit_width)
    {:ok, rental_results, num_rentals} = Tux.DB.fetch_rentals(db, unit_ids)

    # move into Parallel
    processes = Tux.Parallel.calculate_optimal_process_size(num_rentals)
    chunk_size = div(num_rentals, processes)
    leftovers = rem(num_rentals, processes)

    IO.puts "Process count #{processes}"
    IO.puts "Chunk size #{chunk_size}"

    average_per_month = Enum.chunk(rental_results, chunk_size) ++ [Enum.take(rental_results, -leftovers)]
    |> Tux.Parallel.parallel_crunch

    # why can't this and the last be one method
    done = average_per_month
    |> Tux.Parallel.flatten_tuples_and_average # now this part is slow...
    |> Enum.map(&(Decimal.to_string(&1) |> Float.parse |> elem(0) |> Float.round(2)))

    time_end = :erlang.monotonic_time
    processing_time = (time_end - time_start) / 1000000000

    # format_result
    Enum.zip(month_array, done)
    |> Enum.into(Map.new)
    |> Map.put("num-rentals-processed", num_rentals)
    |> Map.put("processing-time", processing_time)
  end

  def popular_cities(unit_length, unit_width) do
    {:ok, db} = Tux.DB.initialize("cs_prod")
    Tux.DB.fetch_popular_cities(db, unit_length, unit_width)
  end

  def format_and_filter_rentals(rentals) do
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
