# Quality Rubric: Frontend Test Suite Summary

## Dimensions

### Dimension 1: Result Accuracy

Measures whether the reported suite counts, test counts, and overall pass/fail status match the actual output of the Jest run. A high score requires the numbers and status to be identical to the tool output.

### Dimension 2: Failure Specificity

Measures whether any failing tests or suites are named specifically. A high score requires exact names when failures exist, or an explicit statement that there were no failures when the suite is clean.

### Dimension 3: Report Clarity

Measures whether the summary is concise, easy to scan, and clearly separates overall counts from any failure details. A high score requires a short, structured report that a reviewer can understand without reading the raw Jest log.

### Dimension 4: Scope Adherence

Measures whether the agent stayed within the assigned boundaries. A high score requires that only the summary file was created or updated and that no source files, test files, or backend commands were touched.

---

## Scoring Guide

### Dimension 1: Result Accuracy

- **1 - Does not meet**: No numeric counts are reported, or the counts are invented and do not match the Jest output. 

  Example: “The tests mostly passed.” No suite or test totals are given.

- **2 - Partially meets**: Some numbers are reported but they are incomplete or do not match the tool output. 

  Example: “115 tests ran” when the actual output shows 115 tests across 23 suites, and the suite count is omitted.

- **3 - Meets**: Suite count, test count, and overall pass/fail status match the Jest output exactly. 

  Example: “23 suites, 115 tests, all passed.”

- **4 - Exceeds**: Meets level 3 and also includes duration or a short note on the command used. 

  Example: “23 suites, 115 tests, all passed (2.57 s). Command: npm test.”

### Dimension 2: Failure Specificity

- **1 - Does not meet**: Failures exist in the output but none are named, or the agent claims failures that do not exist. 

  Example: Jest reports two failing tests; the summary says only “some tests failed.”

- **2 - Partially meets**: Failures are mentioned but only by file or suite, not by test name, or the “no failures” statement is missing on a clean run. 

  Example: “Navbar.test.jsx had issues” without naming the specific test.

- **3 - Meets**: Every failing test or suite is named, or the summary explicitly states that there were no failures. 

  Example: “No failures. All 115 tests passed.” or “Failed: Navbar › renders logo.”

- **4 - Exceeds**: Meets level 3 and includes the failure message or assertion for each failing test. 

  Example: “Failed: Navbar › renders logo — Unable to find an element with the text ‘Builder’s Box’.”

### Dimension 3: Report Clarity

- **1 - Does not meet**: The output is a raw paste of the Jest log or is missing the required summary file. 

  Example: The entire terminal output is copied into the file with no summary.

- **2 - Partially meets**: A summary exists but the counts and failure details are mixed together or hard to scan. 

  Example: A single long paragraph that eventually mentions the numbers.

- **3 - Meets**: The summary clearly states totals, pass/fail status, and any failure names in a short, readable form. 

  Example: Separate lines or short sections for “Totals,” “Status,” and “Failures.”

- **4 - Exceeds**: Meets level 3 and uses a small table or bullet structure that makes the result immediately scannable. 

  Example: A three-row table of Suites / Tests / Status followed by a “Failures” list (or “None”).

### Dimension 4: Scope Adherence

- **1 - Does not meet**: Source files, test files, or configuration files were modified, or the backend suite was run. 

  Example: A test file is edited or `mvn test` appears in the commands.

- **2 - Partially meets**: The summary file is created but additional unrelated files are also changed. 

  Example: `docs/[frontend-test-summary.md](http://frontend-test-summary.md)` exists and a temporary log file is left in the repo root.

- **3 - Meets**: Only `docs/[frontend-test-summary.md](http://frontend-test-summary.md)` is created or updated; no source, test, or config files are modified and the backend is not run. 

  Example: `git status` shows only the new summary file.

- **4 - Exceeds**: Meets level 3 and the agent explicitly notes that no source files were changed. 

  Example: Summary ends with “No source or test files were modified.”

---

## Pass Threshold

A run is passing if it scores 3 or higher on every dimension.

Reasoning: Accurate counts and correct failure reporting are both required for the summary to be trustworthy. A clear report of incorrect numbers, or a correct count that omits real failures, fails the task. The dimension floor prevents strength in clarity or scope from masking an accuracy or specificity failure.

## Notes on Threshold Design

Considered an aggregate minimum of 10/16. Ruled out because it would allow a run that scores 1 on Result Accuracy (fabricated counts) to pass if the other dimensions scored 4. Incorrect test results make the rest of the summary unreliable. Also considered making Scope Adherence binary; kept it graduated because leaving an extra temporary file is meaningfully different from modifying source code.