WITH tb_start AS (
    SELECT
        hotel,
        is_canceled,
        deposit_type,
        season,
        CASE
            WHEN booking_lead_time_days <= 15 THEN 'Last minute'
            WHEN booking_lead_time_days BETWEEN 16 AND 70 THEN 'Standard'
            WHEN booking_lead_time_days BETWEEN 71 AND 160 THEN 'Early'
            ELSE 'Xtra early'
        END AS leading_booking_group
    FROM {{ref('int_bookings_with_season')}}
),

tb_agg AS (
    SELECT
        leading_booking_group,
        hotel,
        deposit_type,
        season,
        SUM(
            CASE 
                WHEN is_canceled = 1 THEN 1 
                ELSE 0 
            END) AS cancelled_bookings,
        COUNT(*) AS total_nb_bookings,
        ROUND((
            SUM(
                CASE 
                    WHEN is_canceled = 1 THEN 1 
                    ELSE 0 
                END)::NUMERIC / COUNT(*)) * 100, 2) AS cancellation_rate_percent
    FROM tb_start
    GROUP BY leading_booking_group, hotel, deposit_type, season
)

SELECT
    *,
    ROUND((total_nb_bookings::NUMERIC / SUM(total_nb_bookings) OVER (PARTITION BY hotel)) * 100, 2) AS share_of_hotel_bookings_percent
FROM tb_agg