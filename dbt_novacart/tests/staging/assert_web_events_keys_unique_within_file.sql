select
    source_file,
    event_id,
    count(*) as record_count

from {{ ref('stg_web_analytics__web_events') }}

group by
    source_file,
    event_id

having count(*) > 1