{{ config(severity='warn') }}

-- test singulier même nb de lignes avant et aprés la jointure en marts

WITH ct_aft_join AS(
	SELECT COUNT(*) AS ct_aft
	FROM {{ref('mart_pricing_consistency')}} 
),

ct_bf_join AS (
	SELECT COUNT(*) AS ct_bf
	FROM {{ref('int_bookings_with_season')}}
)

SELECT *
FROM ct_aft_join AS aft
CROSS JOIN ct_bf_join AS bf 
WHERE ct_aft != ct_bf