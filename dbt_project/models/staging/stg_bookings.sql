WITH source AS (
    SELECT *
    FROM {{ref('hotel_bookings')}}
)

SELECT *
FROM source