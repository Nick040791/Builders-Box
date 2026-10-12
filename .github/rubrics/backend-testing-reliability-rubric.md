# Backend Testing Reliability Rubric

Single source of truth for QA of every change under `backend/`. The `backend-qa` agent (`.github/agents/backend-qa.agent.md`) scores each backend change against the six dimensions below and issues a PASS/FAIL verdict. Gaps are remediated by the `backend-test-engineer` agent (`.github/agents/backend-test-engineer.agent.md`). The full SDLC loop that wires these agents together is defined in `.github/copilot-instructions.md`.

> Repo facts the rubric relies on: Java 17, Spring Boot 3.3.5, JUnit 5 + Mockito, standalone MockMvc, hermetic units throughout (no `@SpringBootTest`), roles `ROLE_ADMIN` and `ROLE_USER`, CI mirror in `.github/workflows/test.yml`.

## Scoring scale

| Score | Meaning |
|---|---|
| 4 — Exemplary | Proficient criteria plus the Exemplary criteria for the dimension |
| 3 — Proficient | Minimum baseline for passing QA; essential criteria hold |
| 2 — Developing | Criteria only partly hold; change is not reliable to merge |
| 1 — Beginning | Criteria largely unmet or absent |

## Pass gate

**PASS = every dimension scores ≥ 3.**

- Any dimension < 3 → **FAIL**; each failing dimension must appear in the remediation gap list.
- Regression clause: any full-suite failure (`mvn clean verify`) fails all dimensions regardless of other criteria.
- Evidence clause: scores cite real evidence — file paths and test method names. A test that does not exist, is skipped (`@Disabled`), or is not executed by the suite earns no credit. Ambiguous evidence scores down.

## Dimensions

### D1 — Layer coverage

Tests must exist and run for every layer the change touched (Controller → Service → DAO), mirroring the source packages under `backend/src/test/java/org/example/`.

| Level | Criteria |
|---|---|
| 4 | Every touched layer has new/updated tests; each names the behavior it proves; adjacent-layer effects (e.g., new service branch changing a DAO query) are also covered |
| 3 | Each touched layer has at least one passing test exercising the changed behavior |
| 2 | Only some touched layers are tested (e.g., controller tested, DAO query change untested) |
| 1 | No tests at any touched layer, or tests exist but do not exercise the change |

### D2 — Failure-mode & boundary coverage

The repo's established failure paths: invalid input, missing ids (404-style outcomes), `DaoException` propagation from DAO to service, empty results, pagination boundaries.

| Level | Criteria |
|---|---|
| 4 | Accept and reject paths tested; boundary values explicit (page/size edges, empty search results); error-response shape asserted (e.g., MockMvc `jsonPath` checks) |
| 3 | Changed behavior has tests for its success path and its primary failure path (validation, not-found, or exception propagation) |
| 2 | Success path only, or failure paths asserted only incidentally |
| 1 | Only the happy path has any coverage, or none at all |

### D3 — Regression safety

| Level | Criteria |
|---|---|
| 4 | Suite green plus a dedicated regression test reproducing the fixed defect's scenario (when the change fixes a defect); SQL-mutating code change also covered by assertion-level mutation tests in the style of `BuildDaoMutationTest` |
| 3 | Full suite green via `mvn clean verify`; existing tests updated (not deleted) when behavior changed; no skipped tests |
| 2 | Suite green but existing scenarios deleted/assertions weakened to get there |
| 1 | Suite red, or tests removed to force it green |

### D4 — Test determinism & quality

| Level | Criteria |
|---|---|
| 4 | Hermetic like `BuildDaoTest` (Mockito-mocked `JdbcTemplate`) and `BuildControllerTest` (standalone MockMvc); SQL argument shape asserted with `ArgumentCaptor` where queries carry authorization/search filters; `<method>_<scenario>_<expected>` naming and a `Proves:` comment for non-obvious intent |
| 3 | Tests are hermetic (mocked collaborators, no real DB/network/file I/O), order-independent, one behavior per test, asserting observable outcomes |
| 2 | Tests share mutable state, depend on execution order, or assert implementation trivia that breaks on refactor |
| 1 | Flaky, environment-dependent, or trivially-asserting tests (assert-no-exception only) |

### D5 — Role & authorization reliability

| Level | Criteria |
|---|---|
| 4 | Cross-role matrix covered: `ROLE_USER`/`ROLE_ADMIN` × public/private × own/other-user data, including escalation negatives (non-admin denied admin-only endpoints, users separated from other users' private rows) |
| 3 | Changes affecting visibility or access have tests exercising the actual roles and ownership boundaries (public vs private parts/builds; other-user private data not returned) |
| 2 | Role checks tested for one role only, or ownership boundaries assumed untested |
| 1 | No authorization/visibility scenario tested for access-affecting changes |

### D6 — CI readiness

| Level | Criteria |
|---|---|
| 4 | No network/manual steps; stable test runtime; change verified by the same commands CI runs (temurin 17 `mvn clean verify`) |
| 3 | New tests run under `mvn test`; no local-only dependencies introduced (e.g., no new required `application.properties` entries, no real MySQL requirement) |
| 2 | Tests pass locally only with manual setup steps |
| 1 | Tests cannot run in CI or require credentials/manual DB setup |

## Agent scoring rules

- Score only what is verifiable from the diff, the test run output, and the repository.
- Record per-dimension evidence: file path + test method name (or CI output snippet).
- If Maven is unavailable in the environment, mark scores provisional and the verdict `REVIEW`; state explicitly that the suite was not executed and hand the change to CI.

## QA report template (`backend-qa` output)

```
## Backend QA Rubric Report — <branch or PR ref>
Suite: mvn clean verify → <PASS|FAIL|not executed>

| # | Dimension | Score | Evidence |
|---|-----------|-------|----------|
| D1 | Layer coverage | <1-4> | <file(s)/test(s)> |
| D2 | Failure-mode & boundary coverage | <1-4> | <...> |
| D3 | Regression safety | <1-4> | <...> |
| D4 | Test determinism & quality | <1-4> | <...> |
| D5 | Role & authorization reliability | <1-4> | <...> |
| D6 | CI readiness | <1-4> | <...> |

Verdict: <PASS | FAIL | REVIEW>
Gaps: <only when not PASS: D# → description, target files>
Handoff: <when FAIL → delegate gap list to backend-test-engineer>
```