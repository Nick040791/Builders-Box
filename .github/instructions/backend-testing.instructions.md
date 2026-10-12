---
applyTo: "backend/src/**/*.java"
---

# Backend conventions (auto-loaded for `backend/src/**`)

Testing conventions for Spring Boot changes. Score targets and escalation come from `.github/rubrics/backend-testing-reliability-rubric.md` (pass gate: every dimension ≥ 3); the QA gate is the `backend-qa` agent.

## Stack

Java 17, Spring Boot 3.3.5. Test deps come from `spring-boot-starter-test`: JUnit 5, Mockito, MockMvc — sufficient for all rubric dimensions. Do not add new test dependencies without explicit need.

## Test style (fixed by existing suite)

- **DAO tests** — mock `JdbcTemplate` with Mockito; no real database. Assert the SQL argument shape with `ArgumentCaptor` whenever the query carries authorization/search/pagination filters. Pair `COUNT` and `SELECT` scenarios for search methods. Patterns: `daos/BuildDaoTest`, `daos/BuildDaoMutationTest`.
- **Service tests** — mock the DAO; cover success and failure propagation (`DaoException`) paths. Pattern: `services/BuildServiceTest`.
- **Controller tests** — `standaloneSetup(controller).build()` MockMvc with a mocked service; mock `Authentication` with `SimpleGrantedAuthority("ROLE_USER")` or `("ROLE_ADMIN")`; assert status codes and JSON shape (`status().isNotFound()`, `jsonPath(...)`). Pattern: `controllers/BuildControllerTest`.
- **Naming** — `method_scenario_expectedOutcome` (e.g., `search_normalUserAll_appliesAuthorizationSearchAndPagination`). Add a short `Proves:` comment block for non-obvious scenarios, matching existing style.
- **Hermetic only** — one behavior per test, order-independent, no `@SpringBootTest`, real DB, network, or filesystem. The suite must stay fast and deterministic.

## Hard rules

- Never delete existing tests, add `@Disabled`, or weaken assertions to obtain green.
- A defect found while testing (test fails because production code is wrong) is escalated, not silently patched — keep the failing test as evidence.
- Access/visibility changes require role + ownership scenarios (public/private × `ROLE_USER`/`ROLE_ADMIN` × own/other-user data).
- New regression tests accompany defect fixes so the scenario cannot silently return (rubric D3).

## Before handing back

Run the suite (`mvn clean verify`) or state plainly that Maven is unavailable. For the official QA verdict, use the `backend-qa` agent; for closing a FAIL verdict's gaps, use the `backend-test-engineer` agent.