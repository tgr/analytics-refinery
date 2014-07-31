-- Selects the missing sequence runs from the webrequest table.
--
-- Sample output:
--
--    hostname            missing_start   missing_end  missing_count
--    --------            -------------   -----------  -------------
--    cp4003.ulsfo.wmnet     1302837053    1302837055              1
--    cp4003.ulsfo.wmnet     1302837059    1302837061              1
--    cp4003.ulsfo.wmnet     1302837066    1302837070              3
--
-- Parameters:
--     table_name        -- Fully qualified table name to look for missing
--                          sequence runs.
--     webrequest_source -- webrequest_source of partition to look for missing
--                          sequence runs.
--     year              -- year of partition to look for missing sequence
--                          runs.
--     month             -- month of partition to look for missing sequence
--                          runs.
--     day               -- day of partition to look for missing sequence runs.
--     hour              -- hour of partition to look for missing sequence
--                          runs.
--
--
-- Usage:
--     hive -f select_missing_sequence_runs.hql   \
--         -d table_name=wmf_raw.webrequest       \
--         -d webrequest_source=bits              \
--         -d year=2014                           \
--         -d month=7                             \
--         -d day=21                              \
--         -d hour=14
--


SELECT
    hostname,
    sequence + 1 AS missing_start,
    next_sequence - 1 AS missing_end,
    next_sequence - sequence - 1 AS missing_count
FROM (
    SELECT
        hostname,
        sequence,
        LEAD(sequence) OVER (
            PARTITION BY hostname ORDER BY sequence ASC
        ) AS next_sequence
    FROM wmf_raw.webrequest
    WHERE webrequest_source = '${webrequest_source}'
        AND year=${year}
        AND month=${month}
        AND day=${day}
        AND hour=${hour}
) webrequest_with_next_sequence
WHERE
    next_sequence IS NOT NULL -- This condition drops the maximum
        -- sequence number per partition per host. LEAD yields NULL
        -- for those.
    AND next_sequence != sequence + 1 -- This condition drops the rows
        -- for which the next sequence number is as expected.
;