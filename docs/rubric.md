# Quality Rubric: Estimate Current Test Coverage and Identify One Weak Area

## Dimensions

### Coverage Measurement Accuracy

Measures whether the agent correctly obtained and reported coverage numbers from the project’s actual tools (JaCoCo for backend, Jest for frontend). A high score requires the reported figures to match the generated reports and both stacks to be addressed.

### Weak Area Specificity

Measures how precisely the agent identified a single area of weak coverage. A high score requires one named package, class, file, or feature rather than a vague description, and the area must be material to the application.

### Evidence Support

Measures whether the choice of the weak area is backed by concrete evidence from the coverage data or test suite. A high score requires cited numbers, uncovered paths, or missing tests that a reviewer can verify.

### Report Clarity and Scope

Measures whether the final report is concise, distinguishes overall coverage from the selected weak area, and stays within the requested task. A high score requires a usable summary that does not modify code or expand into unrelated remediation.

## Scoring Guide

### Coverage Measurement Accuracy

- **1 - Does not meet**: No numeric coverage is reported, or the numbers are invented and do not come from a tool run. 

  Example: “Coverage looks pretty good overall.” No JaCoCo or Jest output is referenced.

- **2 - Partially meets**: Coverage is reported for only one stack, or the numbers are approximate and lack a clear source. 

  Example: “Backend is around 78%.” Frontend is never measured; no report path or command is cited.

- **3 - Meets**: Numeric coverage is reported for both backend and frontend and matches the tool output produced in the run. 

  Example: “JaCoCo line coverage is 78.5% (432/550). Jest statement coverage is 81%.” Both commands and report locations are noted.

- **4 - Exceeds**: Meets level 3 and also reports branch coverage or per-package breakdowns that directly support the weak-area choice. 

  Example: Same overall numbers plus “`org.example.dao` is 62% line / 41% branch; `BuildDao` has 14 uncovered lines in the pagination path.”

### Weak Area Specificity

- **1 - Does not meet**: No weak area is identified, or more than one area is presented as the answer. 

  Example: “Several packages could use more tests.” No single area is chosen.

- **2 - Partially meets**: An area is mentioned but is too vague to act on (e.g., “the backend” or “error handling”).

  Example: “The data layer seems weakly covered.”

- **3 - Meets**: Exactly one specific area is named (package, class, file, or feature).

  Example: “`org.example.service.BuildService` (particularly the private-build ownership checks).”

- **4 - Exceeds**: Meets level 3 and briefly notes why that area was preferred over other low-coverage candidates.

  Example: Same as level 3 plus “Chosen over the generated mapper classes because it contains user-facing authorization logic.”

### Evidence Support

- **1 - Does not meet**: The weak-area claim has no supporting data.

  Example: “BuildService looks under-tested” with no percentage, uncovered lines, or missing test methods cited.

- **2 - Partially meets**: Some evidence is given but it is incomplete or not clearly tied to the named area. 

  Example: “Coverage is lower in services” without naming the class or giving its percentage.

- **3 - Meets**: The weak area is supported by cited coverage numbers or concrete missing tests that match the reports. 

  Example: “BuildService is 54% line coverage; the `updateVisibility` method has no corresponding test in BuildServiceTest.”

- **4 - Exceeds**: Meets level 3 and includes a short pointer to the exact uncovered lines or the absent test scenario. 

  Example: Same plus “Lines 87–94 (ownership check for non-admin users) are uncovered; no test supplies a ROLE_USER principal against another user’s private build.”

### Report Clarity and Scope

- **1 - Does not meet**: The output is a raw tool dump, or the agent modified source code. 

  Example: Pastes the entire JaCoCo HTML or edits a test file.

- **2 - Partially meets**: A summary exists but overall coverage and the weak area are mixed together, or the report is hard to scan. 

  Example: A long narrative that eventually mentions a class but never states the two overall percentages up front.

- **3 - Meets**: The report clearly states overall coverage for each stack, names the single weak area, and cites evidence, without modifying code. 

  Example: Short sections for “Overall,” “Weak Area,” and “Evidence.”

- **4 - Exceeds**: Meets level 3 and adds a one-sentence note on what a follow-up test would need to cover, while still not implementing it. 

  Example: Same structure plus “A single test with a non-owner ROLE_USER principal would cover the missing ownership branch.”

## Pass Threshold

A run is passing if it scores 3 or higher on every dimension.

Reasoning: Accurate measurement and a specifically evidenced weak area are both required for the output to be trustworthy. A clear report of incorrect numbers, or a precise area with no supporting evidence, fails the task. The dimension floor prevents strength in one area from masking a failure in another.

## Notes on Threshold Design

Considered an aggregate minimum of 10/16. Ruled out because it would allow a run that scores 1 on Coverage Measurement Accuracy (fabricated numbers) to pass if the other dimensions scored 4. Incorrect coverage figures make the rest of the report unreliable. Also considered making Weak Area Specificity binary; kept it graduated because “one vague area” is meaningfully different from “no area” and from “one precise area.”