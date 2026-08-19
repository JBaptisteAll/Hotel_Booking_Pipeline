WITH source_data AS (
    SELECT * FROM {{ ref('int_bookings_with_season') }}
),

final AS (
	SELECT 
		hotel,
		DATE_TRUNC('month', arrival_date)::date AS arrival_month,
		ROUND(AVG(booking_lead_time_days), 2) AS avg_booking_lead_time_days,
		
	-- Nb of Bookings (COUNT: no ELSE, NULL is correctly ignored)
		COUNT(*) AS total_bookings,
		COUNT(
			CASE 
				WHEN is_canceled = 0 THEN booking_id
			END
			) AS total_bookings_consumed,
		COUNT(
			CASE 
				WHEN is_canceled = 1 THEN booking_id
			END
			) AS total_bookings_canceled,
			
	-- Nb of Guests
		SUM(adults + children + babies) AS total_guests_booked,
		SUM(
			CASE
				WHEN is_canceled = 0 THEN adults + children + babies
				ELSE 0
			END
			) AS total_guests_consumed,
		SUM(
			CASE
				WHEN is_canceled = 1 THEN adults + children + babies
				ELSE 0
			END
			) AS total_guests_canceled,
			
	-- Nb of Nights
		SUM(nights_weekEND + nights_week) AS total_nights_booked,
		SUM(
			CASE
				WHEN is_canceled = 0 THEN nights_weekEND + nights_week
				ELSE 0
			END
			) AS total_nights_consumed,
		SUM(
			CASE
				WHEN is_canceled = 1 THEN nights_weekEND + nights_week
				ELSE 0
			END
			) AS total_nights_canceled,
		ROUND((
			SUM(
				CASE 
					WHEN is_canceled = 1 THEN nights_weekEND + nights_week
					ELSE 0
				END
				)::NUMERIC
			/ SUM(nights_weekEND + nights_week)) * 100, 2) AS nights_cancellation_rate_percent,
		
	-- Revenue
		ROUND(SUM(average_daily_rate * (nights_weekEND + nights_week))::NUMERIC, 2) AS total_revenue_potential,
		ROUND(
			SUM(
				CASE 
					WHEN is_canceled = 0 THEN average_daily_rate * (nights_weekEND + nights_week)
					ELSE 0
				END
				)::NUMERIC, 2) AS total_revenue_realized,
		ROUND(
			SUM(
				CASE 
					WHEN is_canceled = 1 THEN average_daily_rate * (nights_weekEND + nights_week)
					ELSE 0
				END
				)::NUMERIC, 2) AS total_revenue_missed,
		ROUND((
			SUM(
				CASE 
					WHEN is_canceled = 1 THEN average_daily_rate * (nights_weekEND + nights_week)
					ELSE 0
				END
				)
			/ SUM(average_daily_rate * (nights_weekEND + nights_week)))::NUMERIC * 100, 2) AS cancellation_rate_percent						
	FROM source_data
	GROUP BY hotel,	DATE_TRUNC('month', arrival_date)
)

SELECT 
	*
FROM final

