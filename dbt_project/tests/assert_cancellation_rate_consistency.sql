{{ config(severity='warn') }}

-- test singulier pour la cohérence des pourcentages d'annulation

SELECT
	hotel,
	cancellation_rate_percent
FROM {{ref('mart_cancellation_rate')}}
WHERE cancellation_rate_percent > 100

UNION ALL

SELECT
	hotel,
	SUM(share_of_hotel_bookings_percent)
FROM {{ref('mart_cancellation_rate')}}
GROUP BY hotel
HAVING SUM(share_of_hotel_bookings_percent) NOT BETWEEN 99.9 AND 100.1

