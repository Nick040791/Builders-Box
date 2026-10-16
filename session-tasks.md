# Parallel Agent Session Tasks

## Session A

**Branch name:** `perf/jmeter-report` 
**Worktree directory:** `../Builders-Box-perf` 
**Task:** Run the JMeter load tests and produce a report. 
- Start MySQL and load `database/create-database.sql` (optionally `perf/data/seed-loadtest.sql`). 
- Start the backend on `localhost:8080`. 
- Execute a smoke run: `perf/run-perf.sh 5 30 5`. 
- Execute at least one real run (recommended: `perf/run-perf.sh 25` or `50`). 
- Generate the HTML dashboard. 
- Record p95/p99 latency, throughput, and error % in `perf/RESULTS.md`. 

**Files or folders the agent may write to:** 
- `perf/RESULTS.md` 
- `perf/results/` 
- `perf/report-*/` (HTML dashboards) 

**Files or folders the agent may read but not write to:** 
- `perf/builders-box.jmx` 
- `perf/run-perf.sh` 
- `perf/README.md` 
- `perf/data/` 
- `backend/` 
- `database/` 

**Commands the agent may run:** 
- `perf/run-perf.sh` 
- `jmeter` / `jmeter.bat` (non-GUI) 
- `mvn spring-boot:run` (from `backend/`) 
- MySQL client commands to load schema/seed data 

**Definition of done:** 
- At least one successful smoke run and one real run completed. 
- HTML report generated and browsable. 
- `perf/RESULTS.md` updated with metrics from the run(s). 
- No uncommitted changes outside `perf/`. 

---

## Session B

**Branch name:** `docs/dev-container-setup` 
**Worktree directory:** `../Builders-Box-docs` 
**Task:** Create a Dockerfile and/or dev container configuration plus `setup.md`, then update the README. 
- Create a `Dockerfile` (or `.devcontainer/Dockerfile` + `devcontainer.json`) that provides Java 17, Maven, Node, MySQL client, and Claude Code. 
- Create `setup.md` describing how to build/run the container and point `DB_URL` at `host.docker.internal:3306`. 
- Update `README.md` with a new “Docker / Dev Container” section that links to `setup.md` and gives the minimal start commands. 

**Files or folders the agent may write to:** 
- `Dockerfile` 
- `.devcontainer/` 
- `setup.md` 
- `README.md` 

**Files or folders the agent may read but not write to:** 
- `backend/` 
- `frontend/` 
- `database/` 
- `perf/` 
- `.github/` 

**Commands the agent may run:** 
- `docker build` 
- `docker compose` (if a compose file is added) 
- Read-only inspection of existing files 

**Definition of done:** 
- `Dockerfile` (or `.devcontainer/`) exists and builds successfully. 
- `setup.md` exists with clear instructions. 
- `README.md` contains a new section that references `setup.md` and the container workflow. 
- No changes outside the allowed files. 