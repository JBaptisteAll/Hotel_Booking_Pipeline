WITH source AS (
    SELECT * FROM {{ref('hotel_bookings')}}
),

final AS(
    SELECT
        hotel,
        is_canceled,
        lead_time AS booking_lead_time_days,
        TO_DATE(
		    CONCAT(arrival_date_year, '/' , arrival_date_month, '/', arrival_date_day_of_month),
	    'YYYY/Month/DD') AS arrival_date,
        stays_in_weekend_nights AS nights_weekend,
        stays_in_week_nights AS nights_week,
        adults,
        CASE
		    WHEN children = 'NA' THEN 0
		    ELSE children::integer
	    END AS children,	-- children=10 et babies=9 : unusual values identify, decision to treat into mart
        babies,
        CASE 
            WHEN meal = 'BB' THEN 'Bed & Breakfast'
            WHEN meal = 'FB' THEN 'Full Board'
            WHEN meal = 'HB' THEN 'Half Board'
            WHEN meal = 'SC' THEN 'Self Catering'
		    ELSE 'Undefined'
	    END AS meal,
        country, -- 488 NULLs
        market_segment,
        distribution_channel,
        is_repeated_guest,
        previous_cancellations AS previous_bookings_canceled,
        previous_bookings_not_canceled AS previous_bookings_completed,
        reserved_room_type,
        assigned_room_type,
        booking_changes,
        deposit_type,
        agent, 
        --column 'company' has 116.000 NULL, decision was made not to keep it
        days_in_waiting_list,
        customer_type,
        adr AS average_daily_rate,
        required_car_parking_spaces,
        total_of_special_requests,
        reservation_status,
        reservation_status_date
    FROM source
)

SELECT *
FROM final