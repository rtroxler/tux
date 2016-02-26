defmodule CalcTest do
  use ExUnit.Case
  import Tux.Calc, only: [ compute_month_list: 2, reduce_to_month_map: 1]
  alias Postgrex.Timestamp
  alias Tux.Rental

  test "compute_month_list when moved_in and closed_on are same year" do
    rental = %Rental{
      moved_in_at: %Timestamp{year: 2010, month: 1},
      closed_on:   %Timestamp{year: 2010, month: 8}
    }
    assert compute_month_list(rental.moved_in_at, rental.closed_on) == [1,2,3,4,5,6,7,8]
  end

  test "compute_month_list when moved_in and closed_on are just over a year apart" do
    rental = %Rental{
      moved_in_at: %Timestamp{year: 2010, month: 1},
      closed_on:   %Timestamp{year: 2011, month: 3}
    }
    assert compute_month_list(rental.moved_in_at, rental.closed_on) == [1,2,3,4,5,6,7,8,9,10,11,12,  1,2,3]
  end

  test "compute_month_list when moved_in and closed_on are multiple years apart" do
    rental = %Rental{
      moved_in_at: %Timestamp{year: 2010, month: 1},
      closed_on:   %Timestamp{year: 2012, month: 3}
    }
    assert compute_month_list(rental.moved_in_at, rental.closed_on) ==
     [1,2,3,4,5,6,7,8,9,10,11,12,
      1,2,3,4,5,6,7,8,9,10,11,12,
      1,2,3]

    rental2 = %Rental{
      moved_in_at: %Timestamp{year: 2010, month: 1},
      closed_on:   %Timestamp{year: 2013, month: 3}
    }
    assert compute_month_list(rental2.moved_in_at, rental2.closed_on) ==
     [1,2,3,4,5,6,7,8,9,10,11,12,
      1,2,3,4,5,6,7,8,9,10,11,12,
      1,2,3,4,5,6,7,8,9,10,11,12,
      1,2,3]
  end

  test "compute_month_list when closed_on is nil" do
    rental = %Rental{
      moved_in_at: %Timestamp{year: 2015, month: 11},
      closed_on:   nil
    }

    assert compute_month_list(rental.moved_in_at, rental.closed_on) == [11,12,1,2]
  end


  test "computes month map correctly when rentals span multiple years" do
    rental = %Rental{
      rate: 24.0,
      month_list: [1,2,3,4,5,6,7,8,9,10,11,12,
        1,2,3]
    }
    rental2 = %Rental{
      rate: 44.0,
      month_list: [7,8,9,10,11,12,
        1,2,3,4,5,6,7,8,9]
    }

    assert reduce_to_month_map([rental, rental2]) == %{1 => [24.0, 24.0, 44.0], 2 => [24.0, 24.0, 44.0], 3 => [24.0, 24.0, 44.0],
    4 => [24.0, 44.0], 5 => [24.0, 44.0], 6 => [24.0, 44.0],
    7 => [24.0, 44.0, 44.0], 8 => [24.0, 44.0, 44.0],
    9 => [24.0, 44.0, 44.0], 10 => [24.0, 44.0], 11 => [24.0, 44.0], 12 => [24.0, 44.0]}
  end
end
