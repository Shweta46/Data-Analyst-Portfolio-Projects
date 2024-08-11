{{
    config(
        materialized='incremental', 
        alias='tutor_weekly_late_entry_drilldown',
        unique_key='week_start_teacher_vc',
        post_hook= [
            "{{ postgres_utils.index(this, 'teacher_id') }}"
        ]
    )
}}


SELECT
{{ dbt_utils.surrogate_key(['week_start', 'teacher_id', 'vc_id']) }} as week_start_teacher_vc,
*,
{{ dbt_utils.current_timestamp() }} as updated_at,
'v1'::varchar(10) AS version
FROM (
    SELECT
        final_teacher_id::uuid as teacher_id,
        date_trunc('week', class_scheduled_start_time)::date AS week_start,
        ta.vc_id,
        late_mins,
        CASE 
            WHEN late_mins > 1.0 AND late_mins <= 5.0 THEN '1_5_mins_late'
            WHEN late_mins > 5.0 AND late_mins <= 10.0 THEN '5_10_mins_late'
            WHEN late_mins > 10.0 THEN '10_mins_late'
        END AS late_category
    FROM 
        {{ ref('tutor_activity_premium_courses') }} ta
        LEFT JOIN {{ ref('tutor_fcm') }} fcm on fcm.vc_id = ta.vc_id
    WHERE
        fcm.vc_id is NULL AND
        late_mins > 1.0 AND
        is_regular_teacher_present AND
        {% if is_incremental() %}
            class_scheduled_start_time >= (select max(week_start) FROM {{ this }})
        {% else %}
            class_scheduled_start_time >= date_trunc('week', (now()::date - interval '6 weeks'))
        {% endif %}
) a