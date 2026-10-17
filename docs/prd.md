# PRD: Estimate Current Test Coverage and Identify One Weak Area

## One-Sentence Workflow Description

A single agent estimates current test coverage for the Builders-Box backend (JaCoCo) and frontend (Jest), then identifies one specific area with relatively weak coverage and explains why it is weak.

## Trigger

A developer invokes the agent from the repository root with a prompt such as: “Estimate current test coverage and identify one area with weak coverage.”

## Decision Events

- Decides which coverage tools and commands to run based on the project’s existing setup (JaCoCo via Maven for backend, Jest coverage for frontend).

- Determines whether a full `mvn clean verify` is required or whether an existing JaCoCo report can be reused.

- Chooses one concrete area of weak coverage (a package, class, feature, or layer) rather than listing many, based on the coverage data and the project’s structure.

- Decides how to characterize “weak” (absolute percentage, relative to the \~78.5% backend baseline, or missing tests for an important path).

## Ordered Actions

1. Confirm the working directory is the Builders-Box repository root.

2. Run the backend coverage generation command (`mvn clean verify` from `backend/`, or an equivalent that produces the JaCoCo report) and locate the report (`backend/target/site/jacoco/index.html` or the XML equivalent).

3. Extract overall backend line (and branch, if available) coverage and identify the lowest-coverage packages or classes.

4. Run frontend coverage (`npm test -- --coverage` from `frontend/`, or the project’s equivalent) and extract overall coverage plus any notably low files or directories.

5. Compare the results against the known baseline (\~125 backend tests, \~115 frontend tests, \~78.5% JaCoCo line coverage) and note any deviation.

6. Select exactly one area with weak coverage. Prefer an area that is material to the application (e.g., a service, DAO, controller, or frontend page/component) over purely generated or trivial code.

7. Write a short report that states the estimated overall coverage for each stack, names the chosen weak area, cites the supporting coverage numbers or missing tests, and briefly explains why the area is considered weak.

## Acceptance Criteria

- The agent reports numeric coverage estimates for both the backend (JaCoCo) and the frontend (Jest), or explicitly states that a stack could not be measured and why.

- Exactly one weak-coverage area is identified; it is named specifically (package, class, file, or feature) rather than described only in general terms.

- The choice of the weak area is supported by cited evidence from the coverage report or test suite (percentage, uncovered lines, or absence of tests for a visible code path).

- The report distinguishes overall coverage from the selected weak area and does not claim coverage numbers that contradict the generated reports.

- No application source code is modified; only read-only inspection and test/coverage commands are executed.