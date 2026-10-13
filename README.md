# Builder's Box — FlexPath Final Project

[![CI](https://github.com/Nick040791/Builders-Box/actions/workflows/test.yml/badge.svg)](https://github.com/Nick040791/Builders-Box/actions/workflows/test.yml)

** Description: Builder's Box is a full-stack application for managing PC parts and computer builds.

- Login/Logout, Search PC parts, add to public or private builds
- Admin users have access to the Admin Page


## Start the application

** Steps:

1. Start MySQL Workbench and configure/connect database, then open the create-database.sql file at 'database\create-database.sql' and run it.
2. Set the database environment variables `DB_USERNAME` and `DB_PASSWORD` (and optionally `DB_URL`) to match your MySQL connection — see [Environment variables](#environment-variables). Credentials are no longer stored in `application.properties`.
3. Run the SpringBoot application at 'backend\src\main\java\org\example\SpringBootApplication.java' to start the backend server.
4. Open a terminal and navigate to the /frontend directory and run the npm commands: 'npm install', then 'npm run build', then 'npm run dev'.
5. Open a browser and navigate to localhost:5173, login with admin:admin, user:admin, or guest_builder:admin (all passwords are the same for demonstration)


## Run the unit tests

** Backend

1. Open a new Java 17 terminal and navigate to /backend.
2. run the command 'mvn clean verify', then 'mvn test'.

** Frontend

1. Open a new terminal and navigate to /frontend.
2. Run the command npm test


## Testing

### Current test counts (measured on branch `qa/repo-hardening`)

| Suite | Count | Source |
|---|---|---|
| Backend (JUnit 5) | 125 tests in 14 test classes, 0 failures, 0 skipped | Maven Surefire report from `mvn clean verify` |
| Frontend (Jest) | 115 tests in 23 test files, all passing | Jest output from `npm test` |
| Backend line coverage (JaCoCo) | 78.5% (432 of 550 lines) | `backend/target/site/jacoco/index.html` |

### Environment variables

The backend reads its database connection from environment variables (see `backend/application.properties.example`):

| Variable | Required | Default |
|---|---|---|
| `DB_URL` | No | `jdbc:mysql://localhost:3306/flexpath_final` |
| `DB_USERNAME` | Yes | none |
| `DB_PASSWORD` | Yes | none |

macOS/Linux:
```bash
export DB_USERNAME=root
export DB_PASSWORD='your-local-password'
```
Windows PowerShell:
```powershell
$env:DB_USERNAME = "root"
$env:DB_PASSWORD = "your-local-password"
```
In IntelliJ/VS Code you can set these in the run configuration's environment variables instead. The unit tests do not need a database or these variables.

### Backend tests and coverage

```bash
cd backend
mvn clean verify
```
This runs all unit tests and writes the JaCoCo coverage report to `backend/target/site/jacoco/index.html`. CI uploads the same report as the `jacoco-coverage-report` artifact on every run (coverage is reported, not enforced).

### Frontend tests

```bash
cd frontend
npm ci
npm test -- --watchAll=false
npm run build
```

### API testing with Postman

Import `postman/Flexpath-API.postman_collection.json` into Postman, start the backend on `localhost:8080`, and run the collection.

### Load testing with JMeter

See [perf/README.md](perf/README.md) for the JMeter suite (`perf/builders-box.jmx`, `perf/run-perf.sh`) and record results in `perf/RESULTS.md`. CI also runs a small `perf-smoke` job (5 users, 30 seconds against MySQL on the GitHub runner) and uploads the HTML dashboard as the `jmeter-smoke-report` artifact. Those numbers come from a shared CI runner and are only a smoke check, not a benchmark.
