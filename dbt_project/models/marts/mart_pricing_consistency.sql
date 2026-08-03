with hotel_median AS(
	SELECT 
		hotel,
		season,
		customer_type,
		PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY average_daily_rate) AS median_adr_by_group
	FROM {{ref('int_bookings_with_season')}}
	group by hotel,	season,	customer_type
)

select 
	b.booking_id,
	b.hotel,
	b.season,
	b.customer_type,
	b.meal,
	b.booking_lead_time_days,
	b.average_daily_rate,
	h.median_adr_by_group,
	b.average_daily_rate - h.median_adr_by_group as adr_diff_absolute,
	(b.average_daily_rate / h.median_adr_by_group) as adr_diff_ratio,
	ROUND((((b.average_daily_rate / h.median_adr_by_group) - 1) * 100)::numeric, 2) as adr_diff_percent
from {{ref('int_bookings_with_season')}} as b 
left join hotel_median as h 
	on h.hotel = b.hotel and
		h.season = b.season and 
		h.customer_type = b.customer_type 
		