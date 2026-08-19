{{ config(severity='warn') }}

-- Test singulier pour faire remonter les mois avec beaucoup d'annulation


WITH threshold AS (
	SELECT 
		hotel,
		PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY cancellation_rate_percent) AS p90_cancellation_rate
	FROM {{ ref('mart_revenue') }}
	GROUP BY hotel
)

SELECT 
	mr.*,
	th.p90_cancellation_rate
FROM {{ ref('mart_revenue') }} AS mr
JOIN threshold AS th
	ON mr.hotel = th.hotel
WHERE mr.total_bookings_canceled > mr.total_bookings_consumed  
	OR mr.cancellation_rate_percent > th.p90_cancellation_rate