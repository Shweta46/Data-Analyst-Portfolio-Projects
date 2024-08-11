{{
    config(
        materialized='incremental', 
        alias='revenue_cancellations',
        unique_key='order_id',
        post_hook= [
            "{{ postgres_utils.index(this, 'order_id') }}"
        ]
    )
}}

SELECT
    ro.order_id AS order_id,
    (ro.order_amount - ro.disbursed_revenue - os.round_off_amount) AS cancellation_amount,
    o.currency_id,
    o.country_id,
    now()::date as created_at_date,
    now()::date as cancellation_date

FROM 
    {{ source('sales', 'orders_revenues') }} ro
    INNER JOIN {{ source('sales', 'orders_summaries') }} os ON os.order_id = ro.order_id
    INNER JOIN {{ source('sales', 'orders') }} o ON o.id = ro.order_id

WHERE
    {% if is_incremental() %}
        o.order_date::date <= now()::date - interval '25 days'
        AND
        now()::date > (SELECT max(created_at_date)::date FROM {{ this }})
        AND
        ro.order_id not in (SELECT order_id from {{ this }})
    {% else %}
        o.order_date::date <= now()::date - interval '25 days'
    {% endif %}
    
    AND ro.total_payments_revenue > 0
    AND ro.total_payments_revenue - ro.disbursed_revenue = 0
    AND o.order_amount - ro.disbursed_revenue - os.round_off_amount > 0
    AND o.order_status_id = 1