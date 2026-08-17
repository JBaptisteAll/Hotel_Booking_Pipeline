with tb_start as (
    select
        hotel,
        is_canceled,
        deposit_type,
        season,
        case
            when booking_lead_time_days <= 15 then 'Last minute'
            when booking_lead_time_days between 16 and 70 then 'Standard'
            when booking_lead_time_days between 71 and 160 then 'Early'
            else 'Xtra early'
        end as leading_booking_group
    FROM {{ref('int_bookings_with_season')}}
),

tb_agg as (
    select
        leading_booking_group,
        hotel,
        deposit_type,
        season,
        SUM(case when is_canceled = 1 then 1 else 0 end) as cancelled_bookings,
        COUNT(*) as total_nb_bookings,
        ROUND((SUM(case when is_canceled = 1 then 1 else 0 end)::numeric / COUNT(*)) * 100, 2) AS cancellation_rate_percent
    from tb_start
    group by leading_booking_group, hotel, deposit_type, season
)

select
    *,
    ROUND((total_nb_bookings::numeric / SUM(total_nb_bookings) OVER (PARTITION BY hotel)) * 100, 2) as share_of_hotel_bookings_percent
from tb_agg