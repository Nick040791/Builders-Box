# PRD: Frontend Test Suite Summary

## Overview

A single agent runs the existing frontend test suite and produces a short, accurate summary of the results without modifying any project files.

## One-Sentence Workflow Description

A single agent runs the frontend Jest test suite and writes a concise summary of the results to a documentation file.

## Trigger

A developer invokes the agent from the repository root with a prompt such as: “Run the frontend test suite and summarize the results.”

## Decision Events

- If the test command succeeds and all tests pass, the agent reports the suite and test counts and states that no failures occurred.

- If the test command reports failures, the agent lists the failing suites and tests by name and does not attempt to fix them.

- If the test command cannot be run, the agent reports the error and does not invent counts.

## Ordered Actions

1. Confirm the working directory is the repository root.

2. Change to the `frontend/` directory.

3. Run the project’s frontend test command (`npm test` or the equivalent that executes the Jest suite).

4. Capture the full output, including suite counts, test counts, and any failure names.

5. Write a short summary to `docs/[frontend-test-summary.md](http://frontend-test-summary.md)` that states the total suites, total tests, pass/fail counts, and the names of any failing tests or suites.

6. Do not modify any source files, test files, or configuration files.

## Acceptance Criteria

- The agent reports numeric totals for test suites and individual tests that match the actual Jest output.

- The agent correctly states whether the suite passed or failed.

- If any tests failed, the names of the failing tests or suites are listed; if none failed, the summary explicitly states that there were no failures.

- A file named `docs/[frontend-test-summary.md](http://frontend-test-summary.md)` exists and contains the summary.

- No application source files, test files, or configuration files are modified.

- The backend test suite is not run.