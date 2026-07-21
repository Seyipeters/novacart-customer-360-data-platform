--Load RAW_Campaigns
COPY INTO RAW_CAMPAIGNS (
    campaign_id,
    campaign_name,
    campaign_channel,
    campaign_objective,
    target_segment,
    start_date,
    end_date,
    budget_amount,
    currency,
    campaign_status,
    updated_at,
    source_file,
    source_file_row_number,
    source_file_content_key,
    source_file_last_modified,
    loaded_at
)
FROM (
    SELECT
        t.$1::VARCHAR,
        t.$2::VARCHAR,
        t.$3::VARCHAR,
        t.$4::VARCHAR,
        t.$5::VARCHAR,
        t.$6::DATE,
        t.$7::DATE,
        t.$8::NUMBER(18,2),
        t.$9::VARCHAR,
        t.$10::VARCHAR,
        t.$11::TIMESTAMP_NTZ,
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER,
        METADATA$FILE_CONTENT_KEY,
        METADATA$FILE_LAST_MODIFIED,
        METADATA$START_SCAN_TIME
    FROM @NOVACART_S3_STAGE/marketing_platform/campaigns/ t
)
ON_ERROR = 'ABORT_STATEMENT';

--Validate null and duplicate ids
SELECT
    COUNT_IF(campaign_id IS NULL) AS null_campaign_ids,
    COUNT(*) - COUNT(DISTINCT campaign_id) AS duplicate_campaign_ids
FROM RAW_CAMPAIGNS;

--Validate campaign dates and budgets
SELECT
    COUNT_IF(start_date IS NULL) AS missing_start_dates,
    COUNT_IF(end_date IS NULL) AS missing_end_dates,
    COUNT_IF(end_date < start_date) AS invalid_date_ranges,
    COUNT_IF(budget_amount < 0) AS negative_budgets
FROM RAW_CAMPAIGNS;

--View campaign duration days 
SELECT
    campaign_id,
    campaign_name,
    start_date,
    end_date,
    DATEDIFF('day', start_date, end_date) AS campaign_duration_days
FROM RAW_CAMPAIGNS
ORDER BY campaign_duration_days DESC;

--Inspect channels, objectives and statuses
SELECT
    campaign_channel,
    COUNT(*) AS campaigns,
    SUM(budget_amount) AS total_budget
FROM RAW_CAMPAIGNS
GROUP BY campaign_channel
ORDER BY total_budget DESC;

SELECT
    campaign_objective,
    COUNT(*) AS campaigns,
    SUM(budget_amount) AS total_budget
FROM RAW_CAMPAIGNS
GROUP BY campaign_objective
ORDER BY campaigns DESC;

SELECT
    campaign_status,
    COUNT(*) AS campaigns,
    SUM(budget_amount) AS total_budget
FROM RAW_CAMPAIGNS
GROUP BY campaign_status
ORDER BY campaigns DESC;

--Currency consistency 
SELECT
    currency,
    COUNT(*) AS campaigns,
    SUM(budget_amount) AS total_budget
FROM RAW_CAMPAIGNS
GROUP BY currency
ORDER BY campaigns DESC;
