with hotel_median AS(
	SELECT 
		hotel,
		season,
		customer_type,
		PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY average_daily_rate) AS median_adr_by_group
	FROM {{ref('int_bookings_with_season')}}
	GROUP BY hotel,	season,	customer_type
)

SELECT 
	b.booking_id,
	b.hotel,
	b.season,
	b.customer_type,
	b.meal,
	b.booking_lead_time_days,
	b.average_daily_rate,
	h.median_adr_by_group,
	b.average_daily_rate - h.median_adr_by_group AS adr_diff_absolute,
	(b.average_daily_rate / h.median_adr_by_group) AS adr_diff_ratio,
	ROUND((((b.average_daily_rate / h.median_adr_by_group) - 1) * 100)::NUMERIC, 2) AS adr_diff_percent
FROM {{ref('int_bookings_with_season')}} AS b 
LEFT JOIN hotel_median AS h 
	ON h.hotel = b.hotel AND
		h.season = b.season AND 
		h.customer_type = b.customer_type 
		