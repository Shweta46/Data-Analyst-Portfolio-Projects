{{
    config(
        materialized='view',
        alias='daily_bda_sales_revenue'
    )
}}

SELECT
    "sale_booked_date", "bda_id", sum("revenue") as "revenue", sum("disbursed_revenue") as "disbursed_revenue",
    sum("rejected_revenue") as "rejected_revenue", sum("non_credible_revenue") as "non_credible_revenue",
    sum("realized_revenue") as "realized_revenue", count(distinct id) as "num_sales"
FROM
    (
        SELECT
            o."id", o.order_date::date as "sale_booked_date", ad.id as "bda_id",
            case when ore.currency_id<>1 then 20*total_payments_revenue else total_payments_revenue end as "revenue",
            case when ore.currency_id<>1 then 20*(total_payments_revenue-disbursed_revenue-credible_revenue-non_credible_revenue) else (total_payments_revenue-disbursed_revenue-credible_revenue-non_credible_revenue) end as "rejected_revenue",
            case when ore.currency_id<>1 then 20*disbursed_revenue else disbursed_revenue end as "disbursed_revenue",
            case when ore.currency_id<>1 then 20*(disbursed_revenue+credible_revenue) else (disbursed_revenue+credible_revenue) end as "realized_revenue",
            case when ore.currency_id<>1 then 20*non_credible_revenue  else non_credible_revenue end as "non_credible_revenue"
        FROM
            {{ source('sales', 'orders') }} o
            INNER JOIN {{ source('sales', 'orders_revenues') }} ore on ore.order_id = o.id
            INNER JOIN {{ source('admin_users', 'admin_users') }} ad on ad.id = o.bda_id
        WHERE
            o.order_status_id = 1 and ad.is_active = true
    ) dbsr
GROUP BY "sale_booked_date", "bda_id"
