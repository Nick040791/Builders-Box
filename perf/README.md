# JMeter load tests for Builder's Box

## Files
- `builders-box.jmx`: the test plan (open it in the JMeter GUI to look around, run it non-GUI for real numbers)
- `data/users.csv`: the two non-admin seed accounts from `database/create-database.sql`
- `data/seed-loadtest.sql`: optional, adds 30 public builds so paging and search have data
- `run-perf.sh`: one-line runner that writes the `.jtl` results and the HTML dashboard
- `RESULTS.md`: table to fill in with your real numbers

## Run it
1. Start MySQL, load `database/create-database.sql`, then (optional) `perf/data/seed-loadtest.sql`.
2. Start the backend on `localhost:8080`.
3. Smoke run first: `perf/run-perf.sh 5 30 5`. Every sampler should be green in the dashboard's Statistics table.
4. Real runs: `perf/run-perf.sh 25`, `perf/run-perf.sh 50`, `perf/run-perf.sh 100`.
5. Open `perf/report-50u-*/index.html`, read p95/p99, throughput, and error % from the Statistics table, and copy them into `RESULTS.md`.

Override anything with `-J` flags (see the User Defined Variables on the Test Plan): `host`, `port`, `users`, `ramp`, `duration`, `sla_ms`, `max_page`, `think_min_ms`, `think_range_ms`.
Windows: use `jmeter.bat -n -t builders-box.jmx -Jusers=25 -l results\run.jtl -e -o report-25u` from the `perf` folder.

## What the plan does
- Three thread groups split `users` 70/25/5: Browse, Builder writes, Security checks.
- Each thread logs in once at `POST /auth/login` and reuses `accessToken.token` as a Bearer token.
- Browse: paged `GET /api/builds` and `GET /api/parts`, a search/sort/`hasParts` filter query, detail pages for a random build and part, `GET /api/builds/mine`, `GET /api/profile`.
- Builder: creates a private build, adds a part, reads it back, deletes it (the DB stays clean).
- Security: no token on `/api/builds` must return 401/403, and a non-admin on `/api/users` must return 403. These pass when access is denied.
- Every response is checked for the right status code, key JSON fields, and the 1000 ms SLA.

## .gitignore
```
perf/results/
perf/report-*/
!perf/report-50u-final/
```
