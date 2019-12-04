SELECT
    (extract(epoch from now()) * 1e9)::int8 as epoch_ns,
    pid as tag_pid,
    usename::text AS user,
    extract(epoch FROM (now() - query_start))::int AS duration_s,
    waiting::int,
    case when sa.waiting then
             (select array_to_string((select array_agg(distinct b.pid order by b.pid) from pg_locks b join pg_locks l on l.database = b.database and l.relation = b.relation
                                      where l.pid = sa.procpid and b.pid != l.pid and b.granted and not l.granted), ','))
         else
             null
        end as blocking_pids,
    ltrim(regexp_replace(current_query, E'[ \\t\\n\\r]+' , ' ', 'g'))::varchar(300) AS query
FROM
    pg_stat_activity sa
WHERE
    current_query <> '<IDLE>'
    AND procpid != pg_backend_pid()
    AND datname = current_database()
    AND NOW() - query_start > '500ms'::interval
ORDER BY
    NOW() - query_start DESC
LIMIT 25;
