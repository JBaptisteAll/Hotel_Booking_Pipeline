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
        CASE 
            WHEN adr = 5400 THEN 130
            -- 5400 → 130 : investigated against the full agent=12 / arrival_date=2016-03-25
            -- booking group (same hotel), where every other row is priced at 130.
            -- The 5400 value is inconsistent with the group and treated as a data entry error.
            WHEN adr = -6.38 THEN 62.28
            -- -6.38 → 62.28 : investigated against the agent=273 / arrival_date=2017-03-05
            -- booking group, where 62.28 appears repeatedly among comparable rows.
            ELSE adr
        END AS average_daily_rate,
        required_car_parking_spaces,
        total_of_special_requests,
        reservation_status,
        reservation_status_date
    FROM source
)

SELECT
    ROW_NUMBER() OVER(ORDER BY hotel, arrival_date) AS booking_id,
    -- booking_id : technical row identifier, no business meaning,
    -- used as the technical primary key for dbt tests and future joins.
    *,
    {{ dbt_utils.generate_surrogate_key(
        ['hotel', 'arrival_date', 'booking_lead_time_days', 
        'average_daily_rate', 'agent', 'country', 'reservation_status_date',
        'booking_changes', 'reserved_room_type', 'children',
        'adults', 'nights_week', 'nights_weekend', 'market_segment',
        'days_in_waiting_list']) }} AS duplicate_check_hash
    -- duplicate_check_hash : ~29% of rows share an identical hash across 15 columns,
    -- indicating this dataset doesn't provide enough information for a reliable
    -- individual booking ID (known limitation of the Kaggle dataset, no native ID).
    -- Column kept for data quality investigation purposes, NOT as a primary key.
FROM final