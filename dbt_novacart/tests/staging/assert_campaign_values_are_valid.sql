select
    campaign_source_record_id,
    campaign_id,
    campaign_name,
    start_date,
    end_date,
    budget_amount,
    currency,
    campaign_status

from {{ ref('stg_marketing_platform__campaigns') }}

where end_date < start_date
   or budget_amount < 0
   or trim(currency) = ''
   or trim(campaign_status) = ''