-- Aggregate daily uniques on uri_host and
-- keep only hosts having more than 1000 uniques daily.
--
-- Parameters:
--     source_table           -- Table containing source data
--     destination_directory  -- Table where to right newly computed data
--     year                   -- year of the to-be-generated
--     month                  -- month of the to-be-generated
--     day                   -- day of the to-be-generated
--
-- Usage:
--     hive -f last_access_uniques_daily_to_archive.hql \
--         -d source_table=wmf.last_access_uniques_daily \
--         -d destination_directory=/tmp/archive/last_access_uniques_daily \
--         -d year=2016 \
--         -d month=1 \
--         -d day=1


-- Set compression codec to gzip to provide asked format
SET hive.exec.compress.output=true;
SET mapreduce.output.fileoutputformat.compress.codec=org.apache.hadoop.io.compress.GzipCodec;


INSERT OVERWRITE DIRECTORY "${destination_directory}"
    -- Since "ROW FORMAT DELIMITED DELIMITED FIELDS TERMINATED BY ' '" only
    -- works for exports to local directories (see HIVE-5672), we have to
    -- prepare the lines by hand through concatenation :-(
    -- Set 0 as volume column since we don't use it.
    SELECT
        CONCAT_WS('\t', uri_host, cast(uniques_estimate AS string)) line
    FROM (
        SELECT
            uri_host,
            SUM(uniques_estimate) as uniques_estimate
        FROM ${source_table}
        WHERE year=${year}
            AND month=${month}
            AND day=${day}
        GROUP BY
            uri_host
        HAVING
            SUM(uniques_estimate) >= 1000
        ORDER BY
            uniques_estimate DESC
        LIMIT 100000000
    ) uniques_transformed
;
