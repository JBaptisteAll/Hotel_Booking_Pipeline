{{ config(severity='warn') }}

-- test singulier même nb de lignes avant et aprés la jointure en staging

with ct_aft_join AS(
	SELECT COUNT(*) as ct_aft
	FROM {{ref('int_bookings_with_season')}} 
),

ct_bf_join as (
	SELECT COUNT(*) as ct_bf
	FROM {{ref('stg_bookings')}}
)

select *
from ct_aft_join as aft
cross JOIN ct_bf_join as bf 
where ct_aft != ct_bf