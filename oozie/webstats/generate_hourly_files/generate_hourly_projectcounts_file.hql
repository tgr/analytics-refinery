SET hive.exec.compress.output=false;
--^ To work around HIVE-3296, we have SETs before any comments

-- Generates an hourly webstats projectcounts file into HDFS
--
-- Parameters:
--     destination_directory -- Directory in HDFS where to store the generated
--                          data in
--     source_table      -- table containing hourly aggregated webstats data
--     year              -- year of the to-be-generated hour
--     month             -- month of the to-be-generated hour
--     day               -- day of the to-be-generated hour
--     hour              -- hour of the to-be-generated-hour
--
--
-- Usage:
--     hive -f generate_hourly_projectcounts_file.hql  \
--         -d destination_directory=/tmp/foo         \
--         -d source_table=wmf.webstats              \
--         -d year=2014                              \
--         -d month=4                                \
--         -d day=1                                  \
--         -d hour=0
--

INSERT OVERWRITE DIRECTORY "${destination_directory}"
    -- Since "ROW FORMAT DELIMITED DELIMITED FIELDS TERMINATED BY ' '" only
    -- works for exports to local directories (see HIVE-5672), we have to
    -- prepare the lines by hand through concatenation :-(
    SELECT CONCAT_WS(
       " ",
       qualifier,
       "-",
       cast(SUM(count_views) AS string),
       cast(SUM(total_response_size) AS string)
    ) line FROM ${source_table}
    WHERE year=${year}
        AND month=${month}
        AND day=${day}
        AND hour=${hour}
    GROUP BY qualifier
    ORDER BY line
    LIMIT 100000;
