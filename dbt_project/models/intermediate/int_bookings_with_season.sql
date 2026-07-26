WITH bookings AS (
    SELECT * FROM {{ref('stg_bookings')}}
), 

seasons AS (
    SELECT * FROM {{ref('seed_hotel_seasons')}}
)

SELECT 
    b.*,
    s.season
FROM bookings AS b
LEFT JOIN seasons AS s ON b.hotel = s.hotel AND 
                            s.month = extract(MONTH FROM b.arrival_date)