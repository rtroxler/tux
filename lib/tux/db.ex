defmodule Tux.DB do
  import Postgrex, only: [query!: 3, query!: 4]


  def initialize(db_name) do
    Postgrex.start_link(hostname: "localhost", username: "postgres", password: "postgres", database: db_name, timeout: 15000)
  end

  def fetch_facilities(pid, city) do
    result = query!(pid, """
    SELECT addressable_id FROM addresses
      WHERE addresses.addressable_type = $1
      AND addresses.city = $2
    """, ["Facility", city])
    { :ok, List.flatten(result.rows) }
  end

  ########
  # Units
  ########
  def fetch_units(pid, facility_ids, unit_length, unit_width) do
    result = query!(pid, """
    SELECT id from units
      WHERE units.length = $1
      AND units.width = $2
      AND units.facility_id = ANY ($3)
    """, [unit_length, unit_width, facility_ids])
    { :ok, List.flatten(result.rows)}
  end

  def fetch_units(pid, unit_length, unit_width) do
    result = query!(pid, """
    SELECT id from units
      WHERE units.length = $1
      AND units.width = $2
    """, [unit_length, unit_width])
    { :ok, List.flatten(result.rows)}
  end



  #########
  # Rentals
  #########

  def fetch_rental_rates(pid, facility_ids, unit_ids) do
    result = query!(pid, """
    SELECT current_rate from ledgers
      WHERE ledgers.facility_id = ANY ($1)
      AND ledgers.unit_id = ANY ($2)
    """, [facility_ids, unit_ids])
    { :ok, List.flatten(result.rows), result.num_rows }
  end

  def fetch_rentals(pid, facility_ids, unit_ids) do
    result = query!(pid, """
    SELECT current_rate, moved_in_at, closed_on from ledgers
      WHERE ledgers.facility_id = ANY ($1)
      AND ledgers.unit_id = ANY ($2)
    """, [facility_ids, unit_ids])
    { :ok, result.rows, result.num_rows}
  end

  def fetch_rentals(pid, unit_ids) do
    result = query!(pid, """
    SELECT current_rate, moved_in_at, closed_on from ledgers
      WHERE ledgers.unit_id = ANY ($1)
    """, [unit_ids], [timeout: 15000])
    { :ok, result.rows, result.num_rows}
  end

  # This is a doozy, and also slow (5-6 seconds each time) make it two queries, maybe?
  # select a.city, a.state, count(l.id) from addresses a join facilities f on f.id = addressable_id and a.addressable_type = 'Facility' join ledgers l on l.facility_id = f.id join units u on l.unit_id = u.id where u.length = 20 and u.width = 20 group by a.city, a.state order by count(l.id) desc limit 10;
  def fetch_popular_cities(pid, unit_length, unit_width) do
    result = query!(pid, """
    SELECT a.city, a.state, count(l.id) FROM addresses a
      JOIN facilities f ON f.id = addressable_id AND a.addressable_type = $1
      JOIN ledgers l ON l.facility_id = f.id
      JOIN units u ON l.unit_id = u.id
      WHERE u.length = $2
      AND u.width = $3
      GROUP BY a.city, a.state
      ORDER BY count(l.id) desc
      LIMIT 10
    """, ["Facility", unit_length, unit_width], [timeout: 15000])

    result.rows
  end
end
