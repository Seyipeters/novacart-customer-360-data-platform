select
    source_file,
    campaign_id,
    count(*) as record_count

from {{ ref('stg_marketing_platform__campaigns') }}

group by
    source_file,
    campaign_id

having count(*) > 1