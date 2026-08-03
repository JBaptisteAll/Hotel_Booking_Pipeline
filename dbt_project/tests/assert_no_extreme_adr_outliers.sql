{{ config(severity='warn') }}

-- test singulier outlier supérieur

WITH median_hotel AS (
	SELECT 
		hotel, season,
		PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY average_daily_rate) AS hotel_median
	FROM {{ref('int_bookings_with_season')}}
	WHERE average_daily_rate > 0
	GROUP BY hotel, season
)

SELECT 
	b.*,
	mh.hotel_median
FROM {{ref('int_bookings_with_season')}} AS b
LEFT JOIN median_hotel AS mh ON mh.hotel = b.hotel AND 
								mh.season = b.season
WHERE b.average_daily_rate > mh.hotel_median *4
