# Builder's Box API performance results

Environment: localhost only. CPU: ____  RAM: ____  OS: ____  JDK: ____  MySQL: ____
Commit tested: `____`   Date: ____   SLA used for the Duration Assertion: 1000 ms

Traffic mix: 70% browse (paged/search builds, parts, details, my builds, profile), 25% writes (create build, add part, delete build), 5% security checks (no token, non-admin hitting `/api/users`).

| Users | Ramp (s) | Duration (s) | Samples | p95 (ms) | p99 (ms) | Throughput (req/s) | Error % | Notes |
|---|---|---|---|---|---|---|---|---|
| 25 | 30 | 180 | | | | | | |
| 50 | 30 | 180 | | | | | | |
| 100 | 30 | 180 | | | | | | |

Slowest endpoints at 50 users (p95): ____

What I found / changed: ____ (e.g. added an index, fixed an N+1 query, re-ran: p95 went from ___ to ___ ms)
