{{ config(severity='warn') }}

-- test singulier même nb de lignes avant et aprés la jointure en staging

WITH ct_aft_join AS(
	SELECT COUNT(*) AS ct_aft
	FROM {{ref('int_bookings_with_season')}} 
),

ct_bf_join AS (
	SELECT COUNT(*) AS ct_bf
	FROM {{ref('stg_bookings')}}
)

SELECT *
FROM ct_aft_join AS aft
CROSS JOIN ct_bf_join AS bf 
WHERE ct_aft != ct_bf