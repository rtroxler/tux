defmodule Tux.Parallel do

  def process(rental_results, num_rentals, time_start) do
    processes = Tux.Parallel.calculate_optimal_process_size(num_rentals)
    chunk_size = div(num_rentals, processes)
    leftovers = rem(num_rentals, processes)

    average_per_month = Enum.chunk(rental_results, chunk_size) ++ [Enum.take(rental_results, -leftovers)]
    |> parallel_crunch

    # this and above should be one method
    done = average_per_month
    |> flatten_tuples_and_average # now this part is slow...
    |> Enum.map(&(Decimal.to_string(&1) |> Float.parse |> elem(0) |> Float.round(2)))

    time_end = :erlang.monotonic_time
    processing_time = (time_end - time_start) / 1000000000 |> Float.round(3)

    # format_result
    Enum.zip(Tux.month_array, done)
    |> Enum.into(Map.new)
    |> Map.put("num-rentals-processed", num_rentals)
    |> Map.put("processing-time", processing_time)
  end

  def parallel_crunch(chunked_avgs) do
    c = chunked_avgs
    |> Stream.map( fn rental_chunk ->
        Task.async(fn -> crunch_some_data(rental_chunk) end) end)
    |> Enum.map(&Task.await(&1, 45000))
  end

  def crunch_some_data(rentals) do
    rentals
    |> Tux.Calc.format_and_filter_rentals
    |> calculate_parallel_averages
  end

  # Move me to calc, along with all the other shit
  def calculate_parallel_averages(rentals) do
    rentals
    |> Enum.map(&Tux.Calc.compute_month_list(&1))
    |> Tux.Calc.reduce_to_month_map
    |> reduce_to_top_bottom_tuple
  end

  def reduce_to_top_bottom_tuple(month_map) do
    Enum.reduce(1..12, [], fn month, acc ->
      rates = Dict.get(month_map, month)
      acc ++ [{Tux.Calc.sum_rates(rates), Enum.count(rates)}]
    end)
  end

  def flatten_tuples_and_average(tuple_list) do
    tuple_list
    |> Enum.reduce(Tux.Calc.base_tuple_list, fn list_of_tuples, acc ->
      Enum.zip(acc, list_of_tuples) |> Enum.map(fn {{x, y}, {a,b}} -> {Decimal.add(x, a), y + b} end)
    end)
    |> Enum.map(fn {top, bottom} -> Decimal.div(top, Decimal.new(bottom)) end)
  end



  def calculate_optimal_process_size(num_rentals) do
    cond do
      Enum.member?(100_000..500_000, num_rentals) ->
        2500
      Enum.member?(50_000..99_999, num_rentals) ->
        1000
      Enum.member?(1000..49_999, num_rentals) ->
        100
      Enum.member?(100..999, num_rentals) ->
        10
      true -> 1
    end
  end

end
