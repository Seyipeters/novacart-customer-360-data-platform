with campaigns as (

    select 
        campaign_id,
        campaign_name,
        campaign_channel,
        campaign_objective,
        campaign_status,
        target_segment,
        start_date,
        end_date,
        campaign_duration_days,
        currency,
        campaign_source_updated_at,
        latest_loaded_at

    from {{ ref ('int_marketing_platform__campaign_engagement_summary') }}
),

final as (

    select 
       {{dbt_utils.generate_surrogate_key(
            ['campaign_id']
        )}} as campaign_key,
        campaign_id,
        trim(campaign_name) as campaign_name,
        trim(campaign_channel) as campaign_channel,
        trim(campaign_objective) as campaign_objective,
        trim(campaign_status) as campaign_status,
        trim(target_segment) as target_segment,
        start_date,
        end_date,
        campaign_duration_days,
        upper(trim(currency)) as currency,
        campaign_source_updated_at,
        latest_loaded_at

    from campaigns

)

select *
from final