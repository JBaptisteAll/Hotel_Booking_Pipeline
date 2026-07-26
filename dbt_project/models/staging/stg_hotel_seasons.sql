WITH source AS (
    SELECT * FROM {{ref('hotel_seasons')}}
)

SELECT *
FROM source