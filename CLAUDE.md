# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Builder's Box: a full-stack app for managing PC parts and computer builds. Spring Boot 3.3.5 / Java 17 / Maven backend (`backend/`), React 18 + Vite 5 frontend (`frontend/`), MySQL schema and seed data in `database/create-database.sql`. Demo logins are `admin`, `user`, `guest_builder`, all with password `admin`.

## Commands

Backend (run from `backend/`):
- `mvn clean verify`: build plus the full unit suite (same as CI). It also writes the JaCoCo report to `target/site/jacoco/index.html`.
- `mvn test -Dtest=BuildControllerTest`: run one test class. For a single method, use `-Dtest=BuildControllerTest#methodName`.
- Run the app with `mvn spring-boot:run` or the `org.example.SpringBootApplication` main class. It serves on `:8080`. It needs `DB_USERNAME` and `DB_PASSWORD` set, plus `DB_URL` if you are not using the default `jdbc:mysql://localhost:3306/flexpath_final`. `application.properties` reads these from the environment, so never put real credentials in it.

Frontend (run from `frontend/`):
- `npm ci`, then `npm run dev`: dev server on `:5173`.
- `npm test`: Jest. For one file, use `npx jest src/components/BuildCard.test.jsx`. For one test, use `npx jest -t "test name"`.
- `npm run lint`: ESLint 9.
- `npm run build`: Vite production build.

Unit tests on either side don't need a database. CI (`.github/workflows/test.yml`) runs the backend `mvn clean verify`, the frontend `npm ci && npm test && npm run build`, and a JMeter `perf-smoke` job against a MySQL service container (see `perf/README.md`). A Postman collection lives in `postman/`.

## Architecture

**Backend layering:** controllers → services → DAOs → `JdbcTemplate` with raw SQL. There is no JPA or repositories. Models in `org.example.models` are plain POJOs, and DAOs map rows by hand. `DaoException` wraps data-access failures.

**Auth:** login and JWT handling come from the external `security-jwt-base-spring-boot-starter` (fraho). It exposes `POST /auth/login`, which returns `{ accessToken: { token } }`. There is no security config class in this repo. `CustomUserDetailsService` loads users and roles from the `users`/`roles` tables. Controllers carry `@PreAuthorize("isAuthenticated()")` at the class level. Each controller has a private `isAdmin(Authentication)` helper that checks for `ROLE_ADMIN`.

**Visibility/ownership model:** this is the core business rule. Builds and parts have `is_public` and an owner `username`. Controllers pass `auth.getName()` and `isAdmin` down to the service layer:
- Services enforce single-item access by throwing `ResponseStatusException` 404 or 403. For example, a private item can only be accessed by its owner or an admin.
- DAO `search(...)` methods build dynamic SQL for list and search queries. Non-admin users get `AND (is_public = TRUE OR username = ?)`. The methods add visibility, search, and sort filters, plus `LIMIT ? OFFSET ?`. They run a paired `COUNT` query and return a `PageResult<T>` (`content`, `page`, `size`, `totalElements`, `totalPages`).

**CORS:** `config/WebConfig` allows only `localhost:5173` and `127.0.0.1:5173`.

**Frontend:** all API calls go through `src/api/client.js` `apiFetch`. It calls `http://localhost:8080` directly, attaches the JWT from `localStorage["token"]`, and turns failures into `ApiError(status, userMessage)`. On a 401 it clears the token and redirects to `/login`. Per-resource wrappers live in `src/api/*Service.js`. `src/auth/AuthContext.jsx` holds the login state and roles. `components/AdminRoute` guards `/admin`. Routes are defined in `src/App.jsx`. Jest transforms JSX with esbuild through `jest-transform.cjs`, not Babel. Tests sit next to their sources as `*.test.jsx`.

## Backend testing conventions (from `.github/copilot-instructions.md` and `.github/instructions/backend-testing.instructions.md`)

- Tests are hermetic unit tests only. Don't use `@SpringBootTest`, a real database, the network, or the filesystem. Don't add test dependencies beyond `spring-boot-starter-test`.
  - **DAO tests** mock `JdbcTemplate` and use `ArgumentCaptor` to assert the SQL and argument shape whenever a query carries authorization, search, or pagination filters. Pair the `COUNT` and `SELECT` scenarios. Follow the patterns in `BuildDaoTest` and `BuildDaoMutationTest`.
  - **Service tests** mock the DAO and cover both success and `DaoException` propagation.
  - **Controller tests** use `MockMvcBuilders.standaloneSetup(controller)` with a mocked service and a mocked `Authentication` that carries `SimpleGrantedAuthority("ROLE_USER"/"ROLE_ADMIN")`. They assert status codes and `jsonPath`.
- Name tests `method_scenario_expectedOutcome`. Add a `Proves:` comment for non-obvious scenarios.
- Never delete tests, add `@Disabled`, or weaken assertions to get the suite green. If a test exposes a production bug, keep the failing test and report the bug rather than quietly patching around it. Every defect fix needs a regression test.
- Any change to auth or visibility logic needs role and ownership coverage: public/private × `ROLE_USER`/`ROLE_ADMIN` × own/other user's data.
- The QA rubric is `.github/rubrics/backend-testing-reliability-rubric.md`, and every dimension must score ≥ 3 to pass. Frontend-only changes just need `npm test`, plus `npm run lint` when UI logic changes.

## Agentic workflow

Specialist subagents live in `.claude/agents/`:

| Agent | Model | Owns | Refuses |
|---|---|---|---|
| `orchestrator` | opus | plans, handoffs, final acceptance (writes only to `plans/` and `handoffs/`) | code edits |
| `database` | sonnet | `database/` schema, seed data, migrations | app logic, UI, security |
| `data-layer` | sonnet | backend models, DAOs, services, controllers | frontend, DDL, auth config |
| `domain-compatibility` | opus | PC compatibility and validation rules | CRUD, UI, schema |
| `security-auth` | opus | auth, roles, CORS, validation, credentials | non-security features |
| `frontend` | sonnet | `frontend/src` UI, routing, API client | backend, schema, security |
| `testing-qa` | sonnet | tests in both stacks, coverage, Postman/JMeter | production code |
| `devops` | sonnet | Dockerfile, CI workflows, env vars, scripts | business logic |
| `backend-qa` | opus | read-only backend rubric gate (D1–D6 PASS/FAIL) | any edits |
| `backend-test-engineer` | sonnet | closing `backend-qa` gaps with tests | production code |

`backend-qa` and `backend-test-engineer` are Claude versions of the Copilot agents in `.github/agents/`. If you change one version, change the other to match.

Subagents can't start other subagents. The main conversation dispatches work in the order `orchestrator` gives and passes each handoff along.

### Principles

- **Plan first.** No implementation starts until `plans/<feature-slug>.md` exists and is marked `Approved`.
- **Strict scopes.** Each agent refuses work outside its scope and hands it to the agent that owns it.
- **Explicit handoffs.** Use the handoff template below. Agents refuse incomplete handoffs.
- **Separate reviewer.** The implementer never reviews its own change. Every change to `backend/src/` goes through `backend-qa`.
- **Verifiable done.** Done means tests pass, the baseline holds (~125 backend tests, ~115 frontend tests, ~78.5% JaCoCo line coverage), and every acceptance criterion has cited evidence.
- **Human approval for risk.** Schema migrations, security or auth changes, public API changes, and anything that affects production need explicit human sign-off.

### Plan Protocol

`orchestrator` writes `plans/<feature-slug>.md`. Every implementing agent reads the whole plan as its first action and quotes the acceptance criteria that apply to it. A plan contains:

```markdown
# Plan: <Feature>
Status: Draft | Approved | In Progress | Done
## Goal
## Acceptance Criteria
- [ ] <verifiable criterion>
## Agents & Ownership
## Dependencies & Order
## Risks & Human-Approval Items
## Test Expectations
## Decision Log
```

### Handoff Protocol

Write each handoff to `handoffs/` or include it in the conversation, using exactly this template:

```markdown
## Handoff
**From**: <Agent Name>
**To**: <Agent Name>
**Feature / Plan**: plans/<slug>.md
**Status**: Ready for <next step>
**Summary**: <1-3 sentences of what was done>
**Artifacts**:
- <file paths created or modified>
**Acceptance Evidence**:
- <test results, coverage notes, or "pending review">
**Open Items / Risks**:
- <anything the next agent must know>
**Requested Action**: <specific next task>
**Constraints**:
- Do not modify <protected areas>
- Align with <existing pattern or file>
```

### Review and escalation

1. **Plan review:** `orchestrator` or a human approves the plan before implementation.
2. **Self-review:** the implementing agent makes two passes. First, correctness against the plan and existing patterns. Second, edge cases, error handling, test coverage, and security.
3. **Cross-agent review:** a separate reviewer checks the change. Use `backend-qa` for backend changes. If it returns FAIL, send its gap list to `backend-test-engineer`, then run `backend-qa` again.
4. **Final acceptance:** `orchestrator` checks the evidence against the acceptance criteria. Pull requests that touch `backend/src/` must include the `backend-qa` report.

Agents stop and ask the human when acceptance criteria are ambiguous; when a change needs a schema migration, an auth change, or external API keys; when tests fail for reasons outside their scope; or when they aren't confident about compatibility rules or data integrity. They continue on their own for implementation inside an approved plan, for tests that follow existing patterns, and for in-scope documentation.

## Container

`Dockerfile` builds a dev environment with Java 17, Maven, Node, the MySQL client, and Claude Code. Setup is described in `setup.md`. Inside the container, point `DB_URL` at `host.docker.internal:3306` to reach the host's MySQL.
