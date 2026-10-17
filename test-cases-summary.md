# Test Cases Summary

Summary of the Builder's Box automated test suites, ordered from the backend (Maven/JUnit, then JMeter) to the frontend (Jest). This document is derived from reading the test sources; no tests were run to produce it.

| Suite | Tool | Location | Count |
|---|---|---|---|
| 1. Backend unit tests | Maven / JUnit 5 + Mockito | `backend/src/test/java/org/example/` | 125 `@Test` methods in 14 classes |
| 2. Performance tests | Apache JMeter 5.6.3 | `perf/` | 1 plan, 3 thread groups, 13 samplers |
| 3. Frontend unit tests | Jest + React Testing Library | `frontend/src/**/*.test.js(x)` | 107 test declarations in 23 files (about 115 cases after `test.each` expansion) |

---

## 1. Backend: Maven (JUnit 5)

Run with `mvn clean verify` from `backend/` (the same command CI uses). JaCoCo writes its report to `target/site/jacoco/index.html`.

**Conventions** (from `CLAUDE.md`):
- Tests are hermetic: no `@SpringBootTest`, no database, no network, no filesystem.
- Tests are named `method_scenario_expectedOutcome`.
- DAO tests mock `JdbcTemplate` and use `ArgumentCaptor` to assert SQL and argument shape.
- Service tests mock the DAO and cover success and `DaoException` propagation.
- Controller tests use `MockMvcBuilders.standaloneSetup` with a mocked service and a mocked `Authentication`.

Counts by layer: DAO 33, Service 70, Controller 22 (125 total).

### 1.1 DAO layer (`daos/`), 33 tests

| Class | Tests | What it covers |
|---|---|---|
| `BuildDaoTest` | 10 | `search(...)` SQL and arguments for the visibility model. Normal user with all, public and private visibility: `is_public = TRUE OR username = ?` is applied, and private returns only the user's own private builds. Admin with all, public and private visibility: no ownership restriction. Also covers pagination (LIMIT/OFFSET), `totalPages` calculation, an empty `PageResult`, an allowed descending sort, and an invalid sort falling back to `name`. |
| `BuildDaoMutationTest` | 2 | `create` assigns the generated DB id to the build. `addPartToBuild` increments quantity when the part is already in the build. |
| `BuildAdditionalFiltersDaoTest` | 2 | Combined filters use `EXISTS`, and the authorization clause stays first. An empty build-parts filter uses `NOT EXISTS`. |
| `PartDaoTest` | 6 | Normal-user filters, authorization and pagination. Admin has no ownership restriction. Total-pages maths, empty pagination metadata, descending sort, and invalid-sort fallback. |
| `UserDaoTest` | 13 | List users and find by username (found or null). `createUser` hashes the password, inserts and reloads, and wraps an empty result as `DaoException`. `updatePassword` hashes and reloads, and throws `DaoException` on zero rows. `deleteUser` returns the affected row count. Role operations: `getRoles`, `addRole` (including a duplicate insert), `deleteRole`. Row mapping in `mapToUser`. |

### 1.2 Service layer (`services/`), 70 tests

| Class | Tests | What it covers |
|---|---|---|
| `BuildServiceTest` | 35 | **Create:** forces the authenticated user as owner, and rejects a null build, a blank name and a name over 255 characters (400). **Read:** a missing build gives 404, a public build is visible to other users, a private build is visible to its owner and admin, and a private build gives 403 for another user. **Search:** pagination delegation, expanded filters, and 400 for a negative page, size 0 or size over the maximum, with boundary sizes allowed. **Update:** 404 for a missing build, 403 for a non-owner (checked before validation), the owner updates editable fields, admin can edit another user's build, and invalid input gives 400. **Delete:** 404, 403 for a non-owner, owner deletes, admin deletes. **Parts in builds:** the owner can add a public part, a non-owner is blocked, a missing part gives 404, another user's private part gives 403, a non-positive quantity gives 400, admin can modify any build, the owner can remove a part, and a non-owner is blocked on remove. `getPartsInBuild` shows non-admins only public and own-private parts, while admin sees all. |
| `BuildAdditionalFiltersServiceTest` | 2 | All extra filters are forwarded to the DAO. Pagination validation still applies with the extra filters. |
| `PartServiceTest` | 30 | **Create validation:** the owner is forced to the authenticated user. Null part, blank or too-long name, blank or too-long category, too-long brand and model, negative price, and price above the DB maximum all give 400. Null optional fields are allowed. **Read:** a missing part gives 404, a public part is visible to others, a private part is visible to its owner and admin, and a private part gives 403 for another user. **Search:** pagination delegation, negative page, invalid sizes, and boundary sizes. **Update:** 404, 403 before validation, the owner update preserves the username, admin can edit any part, and invalid input gives 400. **Delete:** 404, 403 for a non-owner, owner deletes, admin deletes. |
| `CustomUserDetailsServiceTest` | 3 | Maps credentials, roles and account flags for an existing user. A user with no roles gets empty authorities. A missing user throws `UsernameNotFoundException` and does not load roles. |

### 1.3 Controller layer (`controllers/`), 22 tests

| Class | Tests | What it covers |
|---|---|---|
| `BuildControllerTest` | 7 | Binds all request parameters. Defaults apply when optional parameters are missing. Admin status is passed to the service. Custom page and size are passed through. The private visibility filter is passed through. `findMine` stays unpaginated. The controller requires an authenticated user (`@PreAuthorize`). |
| `BuildAdditionalFiltersControllerTest` | 1 | Binds and forwards the additional build filters. |
| `PartControllerTest` | 6 | Same shape as `BuildControllerTest`, without the visibility test. |
| `ProfileControllerTest` | 2 | Profile and roles come from the current principal. Change password updates the current user. |
| `UserControllerTest` | 6 | List and get users. Create returns the created user. Password update gives 404 for an unknown user. Password update and delete delegate to the DAO. Role endpoints normalize role names. Deleting a missing role gives 404. |

### 1.4 Visibility and ownership coverage

Services cover public vs. private data × owner / other user / admin for builds and parts. The DAO tests cover the SQL side of the same rule: the `is_public = TRUE OR username = ?` clause is present for non-admins and absent for admins.

---

## 2. Backend: JMeter performance tests (`perf/`)

JMeter is a load and smoke test, not a unit suite. It runs end to end against a live backend and MySQL.

**Files:**
- `builders-box.jmx`: the test plan.
- `run-perf.sh [users] [duration_s] [ramp_s]`: non-GUI runner. It writes a `.jtl` file and an HTML dashboard.
- `check-results.py <jtl> [max_error_pct]`: fails the run on any 5xx response or an error rate above the threshold (default 2%).
- `data/users.csv`: the non-admin seed accounts.
- `data/seed-loadtest.sql`: 30 extra public builds for paging and search.
- `RESULTS.md`: results template. It is currently unfilled.

**Parameters** (override with `-J`): `host` (localhost), `port` (8080), `ramp` (30 s), `duration` (180 s), `sla_ms` (1000), `max_page` (1), `think_min_ms` (500), `think_range_ms` (1000).

**Plan structure:** three thread groups split `users` 70/25/5. Each thread logs in once at `POST /auth/login`, expects 200, extracts the token and sends it as a Bearer header. A 0.5–1.5 s think time sits between requests. A global duration assertion enforces the SLA (1000 ms) on every response.

| Thread group | Share | Samplers and assertions |
|---|---|---|
| **Browse** | 70% | `GET /api/builds` (page, size 12), expect 200 with `$.content`, extracts `buildId`. `GET /api/builds` (search A or B, sort by name DESC, `hasParts=true`), expect 200 with `$.content`. `GET /api/parts` (page), expect 200 with `$.content`, extracts `partId`. If a build was found: `GET /api/builds/{id}` (expect 200, `$.id`) and `GET /api/builds/{id}/parts` (expect 200). If a part was found: `GET /api/parts/{id}` (expect 200, `$.id`). `GET /api/builds/mine` (expect 200). `GET /api/profile` (expect 200, `$.username`). |
| **Builder writes** | 25% | Create, add part, delete, so the DB stays clean. `POST /api/builds` creates a private build (expect 201, extracts `newBuildId`). `GET /api/parts` to pick a part. If both ids exist: `POST /api/builds/{id}/parts/{partId}` (expect 201), `GET /api/builds/{new}/parts` (expect 200), and `DELETE /api/builds/{id}` (expect 204). |
| **Security checks** | 5% | `GET /api/builds` with no token must return 401 or 403. After login, `GET /api/users` as a non-admin must return 403. These samplers pass when access is denied. |

**CI (`perf-smoke` job in `.github/workflows/test.yml`):** runs after the backend tests against a MySQL 8.0 service container. It loads the schema and seed data, packages and starts the backend, installs JMeter 5.6.3, and runs `perf/run-perf.sh 5 30 5` (5 users, 30 s). It then runs `check-results.py` with a 2% error allowance (the Browse group can occasionally hit a build that a concurrent Builder thread just deleted) and uploads the HTML report as the `jmeter-smoke-report` artifact.

---

## 3. Frontend: Jest (`frontend/`)

Run with `npm test` from `frontend/` (for one file, `npx jest <path>`). JSX is transformed by esbuild via `jest-transform.cjs`. Tests sit next to their sources. Rendering uses React Testing Library or `react-test-renderer`, and API services are mocked, so no backend is needed.

### 3.1 API client and auth

| File | Tests | What it covers |
|---|---|---|
| `api/client.test.js` | 11 | Token read and clear in `localStorage`. The `Authorization` header and JSON body serialization. 204 and blank bodies return `null`. 400 uses the backend validation reason, or a fallback message when none is usable. 401 clears auth, redirects to `/login` and throws `ApiError`, but does not redirect when already on the login page. 403 stays on the page with a normalized error. 404 gives a not-found error. 5xx gives a non-technical server error. A rejected fetch gives an `ApiError` with status 0. Malformed success JSON gives an `ApiError` instead of a `SyntaxError`. |
| `auth/AuthContext.test.jsx` | 5 (6 cases) | Finishes loading unauthenticated when there is no token. Restores an admin session for both `ADMIN` and `ROLE_ADMIN` (`test.each`). Clears invalid restored auth. Login stores the token, then logout clears it. `useAuth` throws outside `AuthProvider`. |

### 3.2 Components

| File | Tests | What it covers |
|---|---|---|
| `AddPartToBuildModal` | 2 | Loads the user's builds and adds the part to an existing build. Creates a new build and adds the part to it. |
| `Breadcrumbs` | 1 | Ancestor links are rendered, and the current item is not a link. |
| `BuildCard` | 3 | Details, link and visibility. No Delete button without manage rights. Delete is shown for managers and passes the build to `onDelete`. |
| `BuildForm` | 4 | Empty defaults. Submit values. A blank description is sent as `null`. Initial values, cancel and the submitting state. |
| `ConfirmDeleteModal` | 4 | Shows the item name. Confirm. Cancel and Close both cancel. Actions are disabled and "Deleting" is shown while deleting. |
| `Login` | 4 | Successful login and navigation. An error message with no navigation. A fallback message when the rejection has no message. The authenticated state with logout. |
| `Navbar` | 2 | The Admin link is shown for an admin and hidden for a normal user. |
| `Pagination` | 12 | Backend page 0 shown as "Page 1". Previous and Next enabled and disabled at the first and last page. `onPageChange(page ± 1)`. Loading and single-page states disable both buttons. Renders nothing when there are no pages. Disabled buttons never fire `onPageChange`. |
| `PartCard` | 4 | Details, formatted price, link and visibility. No actions when unavailable. Delete for managers. "Add to Build" in authenticated contexts. |
| `PartForm` | 6 | Defaults. Submit values. Blank optional fields are sent as `null`. Initial values. The Saving state disables the Save button. Cancel. |
| `SearchBar` | 5 | Defaults. Restoring initial values. `onSearch` with one complete query object. Reset restores defaults and calls the optional reset action. The loading state. |
| `VisibilityBadge` | 1 (2 cases) | `test.each` renders Public for `true` and Private for `false`. |

### 3.3 Pages

| File | Tests | What it covers |
|---|---|---|
| `AdminPage` | 6 | The console renders for an admin, and a normal user is blocked. Usernames are listed with no password data, and roles load on demand. Deleting a part reloads with the active search state. Deleting a build uses the existing build service. The page moves to the new last page when a deletion makes the current page invalid. |
| `BuildDetailPage` | 7 | Loads a managed build and adds and removes parts. 404 shows a not-found state with a back link. 403 shows an unauthorized state with no retry. A server or network failure offers retry with the normalized message. A failed update keeps the edit form open. A failed delete keeps the confirmation open. An available-parts API failure is visible and retryable. |
| `BuildsPage` | 7 | Requires authentication. Paginated loading with ownership-based management. A new search resets to page 0 and becomes the active query. A failed reload keeps the last good builds and shows the error. A failed create keeps the form open. A failed delete keeps the confirmation open. Successful create and delete refresh the page. |
| `HomePage` | 5 | Auth-loading and login-prompt states. Paginated parts and a public build preview. A successful search becomes the active query for pagination. A failed part search keeps prior results and shows an error. A failed public-build preview is not shown as an empty data set. |
| `LoginPage` | 1 | Renders the `Login` component. |
| `MyPartsPage` | 6 | Requires authentication. Loads owned parts. A failed reload keeps prior content and shows the error. A failed create keeps the form open. A failed delete keeps the confirmation open. Successful create and delete refresh the list. |
| `PartDetailPage` | 2 | Loads a manageable part with a breadcrumb and supports update and delete. Load errors are displayed. |

### 3.4 Utilities

| File | Tests | What it covers |
|---|---|---|
| `utils/format.test.js` | 2 `test.each` + 1 (9 cases) | `formatPrice` gives `$599.99` for 599.99 and `$1,200.00` for `"1200"`, and "—" for `null`, `undefined` and `"not-price"`. `formatDate` formats a valid date and gives "—" for `null`, `""` and an invalid string. |
| `utils/searchPreferences.test.js` | 5 | Stores supported query fields per username, without page or size. Different users get different storage keys. Stale enum values are rejected safely. Corrupt JSON falls back to an empty query. `clear` removes only the selected user's preference. |

---

## Notes

- Counts come from static inspection. The frontend total of about 115 includes `test.each` expansion, and the backend 125 is the number of `@Test` methods. Both match the baseline in `CLAUDE.md` (~125 backend, ~115 frontend).
- The frontend tests give heavy coverage to failure paths. A recurring pattern is that a failed reload, create or delete keeps the previous content or form and shows a normalized error.
- The backend controller tests do not exercise 403 or ownership responses. Ownership is enforced in the service layer, where it is tested.
- `perf/RESULTS.md` has not been filled in with real run numbers. Only the CI smoke run (5 users, 30 s) is automated.
