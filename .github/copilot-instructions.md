# Copilot Instructions — Builder's Box

Full-stack PC-parts & build manager. Keep answers grounded in these repo facts.

## Project map

| Path | What it is |
|---|---|
| `backend/` | Spring Boot 3.3.5, Java 17, Maven. REST API with `controllers` → `services` → `daos` (`JdbcTemplate`), models in `org.example.models`, JWT auth (`security-jwt-base-spring-boot-starter`). Entry point `org.example.SpringBootApplication` |
| `backend/src/main/resources/application.properties` | Local MySQL connection (user/password are per-developer; do not commit real credentials) |
| `backend/src/test/` | Hermetic unit tests: Mockito-mocked DAOs, standalone MockMvc controllers (no `@SpringBootTest`) |
| `frontend/` | React 18 + Vite 5, react-router-dom, Jest + Testing Library, ESLint 9. `api/` services, `auth/AuthContext`, `components/`, `pages/` |
| `database/create-database.sql` | MySQL schema: `users`, `roles`, `parts`, `builds`, `build_parts` |
| `.github/rubrics/` | QA rubrics (single source of truth for QA scoring) |
| `.github/agents/` | Repository custom agents: `backend-qa`, `backend-test-engineer` |
| `.github/instructions/` | Path-scoped convention files (loaded automatically for matching paths) |

Roles in play: `ROLE_ADMIN` (admin page access) and `ROLE_USER` (standard login). Demo users: `admin`/`user`/`guest_builder` (README).

## Verified commands

| Task | Command |
|---|---|
| Backend build + full suite (CI parity) | `cd backend && mvn clean verify` |
| Backend tests only | `cd backend && mvn test` |
| Frontend tests | `cd frontend && npm test` |
| Frontend lint | `cd frontend && npm run lint` |
| Frontend prod build | `cd frontend && npm run build` |
| CI definition | `.github/workflows/test.yml` (backend tests + frontend tests/build on push & PR) |

## Agentic SDLC loop (backend changes)

The repo's agent architecture: the rubric defines *what quality means*, the agents enforce it, CI re-verifies it.

```text
1. SPECIFY   → restate the change and the layers it touches (Controller/Service/DAO).
2. IMPLEMENT → minimal change; follow .github/instructions/backend-testing.instructions.md for anything under backend/src.
3. TEST      → run `mvn clean verify` (or state clearly if Maven is unavailable and rely on CI).
4. QA GATE   → delegate to the `backend-qa` agent for a scored review against
               .github/rubrics/backend-testing-reliability-rubric.md (pass gate: every dimension ≥ 3).
5. REMEDIATE → if any dimension < 3, send the gap list to the `backend-test-engineer` agent,
               then re-invoke `backend-qa` for the official re-score.
6. DONE      → suite green + rubric PASS → commit/PR; CI re-verifies the same commands.
```

- For PRs (and commits) touching `backend/src/`, include the `backend-qa` rubric report.
- Frontend-only changes skip the backend rubric gate: run `npm test` (and `npm run lint` when UI logic changed) instead.
- When Copilot is asked to "QA this", "score the backend", or "close test gaps", route to the matching agent rather than improvising.

## Working rules

- Backend test style is fixed: hermetic unit tests (Mockito mocks, standalone MockMvc), `method_scenario_expectedOutcome` names, `Proves:` comments for non-obvious scenarios — see `BuildDaoTest`, `BuildDaoMutationTest`, `BuildControllerTest`.
- Never delete tests, add `@Disabled`, or weaken assertions to get green.
- Never commit real MySQL credentials; keep placeholder values in `application.properties`.
- Auth/visibility logic changes must include role + ownership tests (public/private × role × other-user) — rubric dimension D5.