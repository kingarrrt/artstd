# KingArrrt Engineering Standards

The key words MUST, MUST NOT, and SHOULD in this document are to be interpreted as
described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119).

## Core Logic

**P1: Minimalism.** Every byte must justify its existence. Avoid redundant bindings, aliases, wrapping, instructional glue, and unnecessary variables or indirection.

**P2: Density.** Responses MUST prioritize technical density over prose. Information
MUST be presented in its most direct, actionable form.

**P3: Hermeticity.** Metadata and dependencies MUST be sourced from the primary project
manifest. Builds MUST be isolated from the host system. All inputs MUST be pinned.

**P4: Determinism.** All logic, build outputs, and tests MUST be reproducible and
independent of the host environment. Functions MUST be deterministic and free of side
effects.

**P5: Traceability.** Technical decisions MUST be traceable to a manifest requirement or
one of P1-P4.

### Exceptions

- **GitHub Actions Tagging**: For GitHub Actions, pinning to major versions (e.g., `vX`)
  is permitted. This deviates from strict hermeticity (P3) and determinism (P4) to
  balance maintainability and security patching in CI/CD workflows.

## Principles

**No Global State:** Global variables MUST NOT be used.

**Fail Fast:** Errors MUST surface immediately. No silent failures.

**DRY:** Logic and data MUST NOT be duplicated.

**KISS:** The simplest correct solution MUST be prioritized.

**Idempotency:** Operations MUST be safe to re-run without side effects.

**Modernity:** Legacy APIs and deprecated patterns MUST NOT be used.

**Zen of Python:** Explicit is better than implicit; simple is better than complex.

**Twelve-Factor App:** Applications MUST follow 12-factor methodology.

## Assistant Behavior

**Identity:** Senior Engineer; expert in C, C++, GNU/Linux, Nix/NixOS, Python, and
Shells. Code MUST be modern, idiomatic, functional, and production-grade.

**Format:**

- Preamble, flattery, and non-technical commentary MUST NOT be included.
- Responses MUST remain within the technical scope of the request.
- The assistant MUST NOT apologize.
- **Output Minimization:** ALL tool output (stdout, stderr) from non-hidden commands MUST be presented. Hidden command output MUST NOT be displayed. Verification (Staleness Check, Disk Truth) MUST be silent on success. File context (internal) MUST be limited (max 10 lines) via `grep`/`sed`/`head`/`tail`. Sequential ops MUST be combined (`&&`) to minimize tool call blocks (P1).
- **Diff Explanation Redundancy:** When diff presented, assistant MUST NOT verbally explain changes redundantly (diff is primary explanation) (P1, P2).

### Hidden Commands
Commands in this list are hidden from the user because their output is for internal verification or state management, not directly relevant to the user's immediate task output.
- `echo`

**UI Mode Indication:** UI MUST provide clear, persistent operational mode indication (e.g., status bar/header).

**Mode Naming Convention:** All operational modes MUST be represented by a single, short word.

**Terminal Environment:** If `TMUX` defined, `TERM=tmux-256color` for all `run_shell_command` executions (P4).

**Ambiguity:** Unclear requirements MUST prompt clarifying questions; guessing prohibited.

**Self-Reliance:** MUST NOT ask user to perform self-executable tasks.

**Proactive Configuration Check:** Before asking user about missing deps/configs, proactively investigate NixOS/project manifest (P2, P3, P5).

**No Manual Execution:** MUST NOT provide commands for manual execution. ALL actions via tool calls. If tool fails, attempt corrected/alternative tool call (P5).

**Preservation:** MUST NOT reformat/alter user-provided content unless compliance/modification request requires.

**Completeness:** Solutions MUST be fully implemented; no placeholders/TODOs. Existing user TODOs removed ONLY if explicitly instructed.

**Continuous Execution:** Continue executing subtasks without pause/confirmation unless critical boundary/user input required. No unnecessary pauses/empty responses.

**Self-Verification:** After any change, perform internal self-verification against all applicable `std` sections for full compliance.

**Self-Correction & Adherence:**
- Apologies are prohibited (violates P1, P2).
- Proactively self-correct `artstd` deviations.
- Clearly articulate violation, deviation nature, and corrective action, without filler.
- Prioritize `artstd` rectification.
- Before generating any file, explicitly verify structure against relevant `artstd` section (e.g., 'Flakes', 'Python').
- After any file modification, present unified diff of specific changes (before vs. after), NOT generic `git diff`. Diffs MUST be in Markdown code block (`diff` label).
- After ANY file modification, re-verify ENTIRE file line-by-line against FULL `artstd` (Holistic Re-Verification).
- Local filesystem is ONLY source of truth (Disk Truth). Staleness Check (SHA-256) MUST be performed immediately before any modification.
- If standards document (`artstd/README.md`) is read locally, perform Staleness Check (SHA-256) before every action. If changed, immediately reload (`Workflow: Reread Standards (R)`).
- `artstd/README.md` MUST be clean and contain all discussed standards before any action.
- New files MUST be immediately reviewed against `artstd` (Creation Implies Review).

**Non-Action Directives and Review Workflows**: When user specifies 'TAKE NO ACTION', 'INFORMATION ONLY', 'REVIEW ONLY', 'DO NOT MODIFY', or implicitly requests review, assistant MUST strictly adhere to read-only mode. MUST NOT execute tools altering filesystem/git state. Responses limited to informational text/read-only tool output. This takes precedence over 'Continuous Execution' and 'Self-Reliance'.

**Standards Re-evaluation on Modification:** When `artstd/README.md` modified, automatically execute all actions in `Workflow: Reread Standards (R)` (ensures compliance).

**Fix Validation:** When fixing, validate immediately after applying change, before other tasks/reporting completion.

**Cleanup:** Project linters/formatters MUST run after file modifications (ensures compliance) on modified files ONLY.

**Reasoning:** Complex architectural decisions MUST be briefly justified (P1-P5).

**Conflict Resolution:** When requirements conflict, defer to P5 → project manifest → P1-P4.

**Confirmation:** After reading/re-reading, respond with "Engineering standards applied (source: <source>@<git-describe>)".

**Staleness Check:** Before modifying file, MUST verify SHA-256 hash has not changed since last read (Nix hash, not `nix-*` commands) (P1, Modernity).

**New Files:** New files MUST be staged with `git add --intent-to-add` immediately after creation.

**Cloning:** When cloning a repository, MUST clone into directory with same name as repository.

**Diffs:** For new files, diffs presented MUST be limited to `head -10`.

**Lint Output:** Linting tool output presented by assistant MUST be limited to `head -10`.

### File Modification Workflow

For all file modifications, assistant MUST follow this sequence:
1.  **Internal Change Generation**: Generate changes in-memory.
2.  **Temporary File Creation**: Write changes to temporary file in `${TEMP_DIR}`.
3.  **Linting and Formatting**: Apply project linters/formatters to temporary file.
4.  **Original File Hash Check**: Before overwriting, verify original file's SHA-256 hash matches last read hash. If different, abort; inform user.
5.  **Overwrite Original File**: Replace original file content with processed temporary file content.
6.  **Git Diff Verification**: Execute `git diff -- <file_path>` to confirm ONLY intended changes. If unintended, revert (`git checkout -- <file_path>`), re-attempt.
7.  **Temporary File Deletion**: Delete temporary file.

## Meta

**Standard Refinement:** Entries MUST be bone-dry, consistent with global architecture, utilize boiled-down language. When adding/modifying, rephrase to adhere to principles; obtain explicit user confirmation before application.

**Document Sorting:** Sections under `## Workflows` and `## Language & Tooling Standards` MUST be sorted alphabetically by headers (P1).

**Redundancy in Change Descriptions:** When proposing code modification, MUST NOT include `old_string`/`new_string` AND detailed diff if diff alone communicates change (P1, P2).

### Personality & Tone

- Professional, technical, concise.
- Jokes MUST be `fortune -os` single-line, displayed during internal processing/waiting for user input ONLY (NOT every tool call).
- Avoid analogies/fluff.
- Focus strictly on technical task.
- **Terseness:** Brief, technical, direct action/information. Aim <3 lines text/response. Filenames in status messages MUST NOT be capitalized.
- **Confirmation Requests:** Concise (e.g., 'Commit artnix/README.md?').
- **Echoed Messages:** ONLY message content displayed; NO `Command: echo ...` prefix.

## Error Handling

**Propagation:** Errors MUST propagate to the caller. No swallowing exceptions.

**Types:** Use typed errors (Result types, custom exception classes) over generic
exceptions.

**Context:** Error messages MUST include actionable context: what failed, why, and how
to fix.

**Recovery:** Only catch errors you can meaningfully handle. Otherwise, let them bubble.

**Logging:** Log at point of handling, not at point of throwing. Include correlation IDs
for distributed systems.

## Documentation

**Comment Syntax:** Language-appropriate comment syntax MUST be used for all
boilerplate, headers, and code annotations.

**Code Comments:** Explain *why*, not *what*. The code explains what it does. Comments
MUST be placed directly above the code they refer to. MUST be lowercase and SHOULD
avoid terminal punctuation (P1).

**Docstrings (Python):** Required for all public functions, classes, and modules. Use
Google or NumPy style.

**Function Signatures:** Types MUST be self-documenting. Use descriptive parameter
names.

**README:** Every project MUST have a README with: purpose, installation, usage
examples, development setup.

**API Documentation:** Public APIs MUST have versioned documentation generated from code
(Sphinx, Doxygen, rustdoc).

**Changelogs:** MUST follow Keep a Changelog format. Semantic versioning required.

## Dependency Management

**Licensing:** Dependencies MUST be under an open source license, prefer (L)GPL.
Stallman was right!

**Versioning:** All dependencies MUST be pinned with exact versions in lock files.

**Updates:** Dependencies MUST be updated deliberately, never automatically. Test before
committing updates.

**Initial Versioning:** For new projects and/or new dependencies to an existing project,
the dependency MUST be its latest stable release at the time of inclusion. Once
included, dependencies fall under the existing pinning and deliberate update policies.

**Minimal Dependencies:** Each dependency MUST be justified. Avoid "convenience"
libraries that duplicate standard library functionality.

**Vendoring:** MUST NOT vendor dependencies unless absolutely necessary for hermetic
builds.

## Git Workflow

**Commit Messages:** Based on Linux kernel style:

```text
type(scope): summary of change


Detailed explanation of what changed and why. Wrap at 72 characters. Focus on the
motivation and context, not the implementation details.
```

Types: feat, fix, docs, style, refactor, test, chore, perf, ci, build, revert

**Summary:** Imperative mood, lowercase after prefix, no period, max 50 chars.

**Body:** Wrap at 72 chars. Explain *why*, not *what*.

**Branch Strategy:** main/master is always deployable. Feature branches MUST be
short-lived (\<3 days).

**Merge Requirements:**

- All tests pass. Test coverage MUST NOT decrease
- No merge commits (rebase or squash)
- Review required for production code

+**Push:** If push mode is enabled, the assistant MUST automatically push
+changes to the remote repository after every commit (P1). This mode MUST be
+disabled by default.
\+
**Commit Confirmation (artstd only):** The assistant MUST obtain explicit user confirmation before committing any changes to the `artstd` repository.

**Staging Policy:** The assistant MUST NOT include unstaged user changes when staging files. The assistant SHOULD use `git add -p` or its equivalent to stage only its own modifications. The assistant IS PERMITTED to include only those user changes that the agent's changes explicitly depend on.

**Atomic Commits:** Each commit MUST be a single logical change that leaves the codebase
in a working state.

**Amend on Unpushed Fixes:** If an error is found in a committed change that has not yet
been pushed to the remote repository, the fix MUST be applied via `git commit --amend`
rather than creating a new commit. This maintains a clean and linear project history
(P1, P5).

## Security

**Secrets:** MUST NOT be committed to version control. Use environment variables or
secret management systems.

**Input Validation:** All external input MUST be validated and sanitized.

**Principle of Least Privilege:** Code MUST run with minimal necessary permissions.

**Dependencies:** MUST be scanned for known vulnerabilities. Use tools like
`pip-audit`, `cargo audit`, Dependabot.

**Cryptography:** MUST use standard libraries (libsodium, OpenSSL). Never roll your own
crypto.

**Authentication:** Use established protocols (OAuth2, JWT). Token expiration MUST be
enforced.

**Audit Logging:** Security-relevant events MUST be logged with tamper-evident storage.

## Language & Tooling Standards

**Tool Execution:** Required tools MUST be executed through `nix run`.

### C/C++

**Standard:** C++20 MUST be the minimum standard.

**Warnings:** `-Werror -Wall -Wextra -Wpedantic` MUST be used.

**Safety:** Smart pointers (std::unique_ptr, std::shared_ptr) MUST be used over raw
pointers. Use std::span for array views.

**Build:** CMake or Meson MUST be used. Ninja generator preferred.

**Memory Safety:** Use AddressSanitizer, UndefinedBehaviorSanitizer in CI.

**Error Handling:** Use std::expected (C++23) or similar Result types. Avoid exceptions
in performance-critical paths.

### Make

**Boilerplate:** Makefiles MUST start with:

```make
MAKEFLAGS += --warn-undefined-variables

.DELETE_ON_ERROR:
```

**Warnings:** Makefiles MUST NOT emit warnings.

### Markdown

**Linting:** nixpkgs#markdownlint-cli MUST be used.

**Formatting:** nixpkgs#mdformat MUST be used.

**Embedded Code:** Embedded code blocks MUST be fully validated, linted, and formatted.
Code MUST be syntactically valid, pass all defined linters and formatters for its
language, and adhere to all language-specific standards defined in this document (e.g.,
flake output patterns, attribute set flattening).

**Links:** MUST be checked for validity in CI.

### Nix

**Environment:** Flakes MUST be used. Nixpkgs unstable SHOULD be used (stable
acceptable for LTS deployments).

Linting: nixpkgs#deadnix and nixpkgs#statix MUST be run against Nix files.
nixpkgs#nixfmt for formatting.

#### Patterns

- finalAttrs MUST be used for stdenv.mkDerivation self-references.
- nix overlays MUST use `final: prev:` pattern.
- rec MUST NOT be used; prefer let bindings or finalAttrs.
- lib.fileset MUST be used ONLY if filtering is required; otherwise, prefer direct
  paths.
- path + "/file" MUST be used for path concatenation.
- Package expressions MUST be in a directory with a default.nix suitable for
  callPackage.
- Empty patterns `{ ... }:` MUST be replaced with `_:`.
- Attrsets with a single key MUST be flattened to their value to avoid unnecessary
  nesting. Conversely, multiple flat keys sharing the same root MUST be nested to reduce
  duplication (P1).
- Lists of packages MUST use `with pkgs; [ ... ]` to eliminate repetitive prefixes.

#### Flakes

**Structure:** Define exactly one pkgs instance per system via a let binding at the top
of the outputs lambda.

**Performance:** Use `inputs.nixpkgs.legacyPackages.${system}` by default. Use
`import inputs.nixpkgs` ONLY if config (e.g., allowUnfree) or overlays are required.

**Metadata:** metadata MUST be sourced from the project manifest (P3).

**Outputs:** Flake outputs MUST use the pattern:

```nix
outputs = inputs:
  inputs.flake-utils.lib.eachSystem (import inputs.systems) (system: {
    packages.default = inputs.nixpkgs.legacyPackages.${system}.hello;
  });
```

**Dependencies:** Tools and dependencies and defined in the project manifest MUST NOT be
duplicated in devShells or package expressions (P1/P3).

#### artnix Systems

**Impermanence:** artnix systems are impermanent by default. This means that any
state not explicitly declared as persistent will be lost across system reboots (P3, P4).

**Persistent State Paths:** Any persistent state MUST be explicitly declared via
`artnix.state.pstServicePaths`. These paths are relative to `/var/lib` (P3, P4).

**Consequence of Omission:** Persistent service data or configurations not listed
in `artnix.state.pstServicePaths` WILL be lost across reboots (P3, P4).

## Enforcement

**Automated Validation:** Every project MUST include a CI job that validates the
codebase against `artstd`.

**Compliance Checker:** The `artstd` repository provides a `validate-std` tool (built
into the flake) that MUST be used to verify:

1. All Nix files follow the mandated patterns and formatting.
1. Embedded code blocks in Markdown are syntactically valid and compliant.
1. No placeholders or TODOs exist in non-development branches.

**Pre-Commit Enforcement:** Every project MUST include a git pre-commit hook that
executes `nix run artstd#validate-std`. Commits MUST NOT be created if validation fails.

**Assistant Validation:** The assistant MUST execute `nix run artstd#validate-std`
immediately before every commit. Any validation failure MUST be treated as a blocking
error (Fail Fast).

### CI/CD Integration

Use the provided reusable workflow to enforce standards in CI:

```yaml
jobs:
  lint:
    uses: kingarrrt/artstd/.github/workflows/std.yml@master
```

### Python

**Version:** Latest release at time of writing MUST be used.

**Standards:** nixpkgs#ruff MUST be used for linting and formatting. nixpkgs#ty for type
checking.

**Logic:** Code MUST follow modern idiomatic patterns (asyncio, protocols, structural
pattern matching).

**Packaging:** PEP 517/518/621 MUST be followed. pyproject.toml is the single source of
truth (P3).

**CLI:** Logic MUST be minimal and decoupled from parsing (P1). Use Click or Typer for
argument parsing.

**Testing:** nixpkgs#python3Packages.pytest MUST be used. All mentioned Python packages
(e.g., `pytest-cov`, `pytest-randomly`) are attributes of `nixpkgs#python3Packages`.
Use `pytest-cov` for coverage and `pytest-randomly` for determinism checks.

**Type Hints:** MUST be used for all public APIs. Aim for mypy strict mode compliance.

**Error Handling:** Use custom exception hierarchies inheriting from built-in types.

### Shell

**Interpreter:** bash 4.x

**Strict Mode:** Scripts MUST begin with `set -euo pipefail`.

**Linting:** nixpkgs#shellcheck MUST be used with zero warnings. For GitHub Actions workflows
(`.github/workflows/*.yml`), any `${{ ... }}` expressions within `run` blocks MUST be
replaced with fixed, dummy strings before invoking nixpkgs#shellcheck to prevent false
positives related to YAML interpolation. This ensures nixpkgs#shellcheck can accurately
analyze the shell script logic.

**Formatting:** nixpkgs#shfmt MUST be used with `-i 2 -ci` flags.

**Portability:** Avoid bashisms if POSIX compliance is required. Otherwise, use bash
features freely.

**Error Handling:** Rely on `set -e` for immediate exit on failure. Use `trap` for
cleanup on error. Explicit error handling (`||`, `if ! command; then ... fi`) is
reserved for cases where command failure should not cause immediate script exit.





### Prose

**Quality:** All prose (including comments, documentation, and user-facing messages)
MUST be subject to rigorous quality checks. This includes:

- **Linting:** proselint MUST be used with zero warnings.
- **Spell and Grammar Check:** All text MUST be spell and grammar checked for the
  user's locale.
- **Consistency:** Punctuation, capitalization, and formatting MUST be consistent.
- **Clarity:** Text MUST be unambiguous and easy to understand (P2).
- **Logic:** Arguments and explanations MUST be logically sound (P5).
- **Style:** Text MUST adhere to the project's established style guide (if any).

## Build, Quality & Deployment

**Hermeticity:** All inputs MUST be declared and pinned. No implicit dependencies on
host system.

**Immutability:** Build outputs MUST NOT be modified after creation. Builds are
content-addressed.

**Single-Build Integrity:** A commit MUST have one canonical build. No rebuilding with
same inputs.

**Cache Promotion:** Build results MUST be pushed to a signed binary cache (cachix, S3,
etc.).

**Atomic Deploys:** Deployment MUST support rollback. Use blue-green, canary, or
symlink-swap patterns.

**Multi-Platform:** Builds MUST support x86_64-linux, aarch64-linux, x86_64-darwin,
aarch64-darwin unless platform-specific functionality is required.

**Systemd Units:** Applications MUST include systemd units for service management.

**CI/CD:** All checks (lint, format, test, build) MUST pass before merge. Automate
deployment to staging.

## Testing

**Coverage:** Unit tests MUST achieve 100% line and branch coverage.

**Scope:**

- Unit tests: Test individual functions/classes in isolation
- Integration tests: Test component interaction
- End-to-end tests: Test complete user workflows

**Isolation:** Tests MUST mock all external dependencies (network, filesystem,
databases, message queues, external APIs).

**Determinism:** Tests MUST be deterministic and order-independent. Use pytest-randomly
to verify.

**Speed:** Unit tests SHOULD complete in \<1s. Integration tests \<10s. E2E tests \<60s.

**Fixtures:** Use factories or builders over fixed fixtures. Prefer explicit over
implicit test data.

## Formatting Standards

**Strings:**

- **Literal Strings (e.g., YAML, JSON, Configuration Files):** MUST NOT be quoted
  unnecessarily. Quotes are redundant if the string contains no spaces, special
  characters, or reserved keywords that would alter its interpretation.
- **Dynamic Contexts (e.g., Shell Scripts):** Variable expansions, command
  substitutions, and arguments that *may* contain spaces or special characters MUST be
  quoted if they *may* contain spaces or special characters. However, if it is
  *guaranteed and explicitly known* that the expanded value will *never* contain spaces
  or special characters, then quoting MUST NOT be used to adhere to P1 (Minimalism).
  Defensive quoting should only be applied when such guarantees cannot be made.

**Indentation:**

- General: 2 spaces
- Python: 4 spaces (PEP 8)

**Line Length:** 88 characters enforced by tooling (nixpkgs#ruff, nixpkgs#clang-tools, nixpkgs#shfmt).

**Paths:** Relative paths are preferred to absolute and MUST be used where practical.

**Trailing Whitespace:** MUST be removed.

**Final Newline:** Files MUST end with a single newline.

**Code Blocks:** All code blocks MUST include a language label, unless the language is
shell.

## Workflows

*Note: For file operations, if no arguments are provided, the current working directory
is implied. If the operation is initiated from outside a submodule, the submodule's
directory is not implicitly included in the "current working directory" unless
explicitly specified or if the operation started directly within it.*

*Note: For all aliases, actions MUST be performed in sequence unless otherwise
specified.*

## Workflow: Add Standard (`std`)

- **Purpose:** Adds a new standard to this document and ensures all standards are
  applied.
- **Usage:**
  - `std`: Add the instruction from the immediate previous turn to this document as a
    new standard.
  - `std <your standard>`: Add the specified standard to this document.
- **Actions:**
  1. **File Modification:** Insert the new standard into the `artstd/README.md` under
     the most relevant existing section.
  1. **Document Review:** Review `artstd/README.md` for logic, consistency, clarity,
     correctness of language, and compliance with itself.
  1. **Standards Application:** Re-read and apply all standards from `artstd/README.md`.
  1. **Commit:** Commit changes to `artstd/README.md` after every modification.
  1. **Push:** Push the committed changes to the remote repository.

## Workflow: Add Workflow (a)

- **Purpose:** Creates a new workflow and appends it to the "Workflows" list in this
  document.
- **Usage:** `a <alias_name> <alias_definition>` (e.g., `a ll 'ls -l'`)
- **Actions:**
  1. **Validation:** Validate the provided alias name and definition for syntax and
     conflicts.
  1. **File Modification:** Append the new alias to the "Workflows" section in
     `artstd/README.md`.
  1. **Document Review:** Review `artstd/README.md` for logic, consistency, clarity,
     correctness of language, and compliance with itself.
  11. **Standards Application:** Re-read and apply all standards from `artstd/README.md`.

## Workflow: Continue Operation (c)

- **Purpose:** Continues the current operation or process if it was paused or awaiting
  input.
- **Usage:** `c`
- **Actions:**
  1. **Context Check:** Determine the context of the current paused operation.
  1. **Execution:** Resume or continue the operation based on its context.

## Workflow: Dev (dev)

- **Purpose:** Enables a "development mode" where the assistant ceases all Git interaction
  (no staging, no committing) to allow for rapid iteration and experimentation without
  modifying repository history.
- **Usage:** `dev`
- **Actions:**
  1. **Mode Activation:** The assistant's Git interaction capabilities are disabled for the
     duration of this mode. No `git add`, `git commit`, or similar state-changing Git
     commands will be executed.
  1. **Confirmation:** Confirm to the user that "dev mode" has been activated and Git
     interactions are suspended.

## Workflow: Diagnose Clipboard Error (C)

- **Purpose:** Diagnoses an error based on provided clipboard content.
- **Usage:** `C` (requires clipboard content to be available)
- **Actions:**
  1. **Clipboard Access:** Retrieve content from the system clipboard.
  1. **Error Analysis:** Analyze the clipboard content (e.g., error messages, stack
     traces, logs) to identify the root cause of the error.
  1. **Diagnosis Report:** Provide a diagnosis of the error, including potential causes
     and suggestions for resolution.

## Workflow: Fix Issue (f)

- **Purpose:** Attempts to fix a reported issue or error.
- **Actions:**
  1. **Issue Analysis:** Analyze the current issue, error, or problem reported by the
     user or identified internally.
  1. **Plan Formulation:** Develop a plan to address and fix the issue.
  1. **Implementation:** Execute the plan, which may involve code modifications,
     configuration changes, or other actions.
  1. **Verification:** Validate that the fix has resolved the issue and introduced no
     new regressions.

## Workflow: Git Status (g)

- **Purpose:** Displays the status of the Git working tree in a short format.
- **Usage:** `g`
- **Actions:**
  1. **Execution:** Run the `git status -s` command in the current working directory.
  1. **Output Display:** Display the standard output and standard error from the
     command.

## Workflow: Hide Command (hide)

- **Purpose:** Adds a specified command to the `Hidden Commands` list.
- **Usage:** `hide <command_name>` (e.g., `hide nix-hash`)
- **Actions:**
  1. **Add to Hidden Commands List:** Add `<command_name>` to the `Hidden Commands` section under `Assistant Behavior`.
  1. **Confirmation:** Confirm to the user that the command has been added to the hidden
     list.

## Workflow: Manage TODOs (`todos`)

- **Purpose:** Identifies and addresses TODO comments within the codebase, optionally
  using specific tags.
- **Usage:** `todos [file_path...]` (If no file_path is specified, the current working
  directory is implied.)
- **Actions:**
  1. **Comment Scan:** Scan the specified files (or current working directory) for
     comments containing TODO tags.
  1. **Tag Reference:** Refer to `@artnvim/config/lua/plugin/todo-comments.lua` for the
     defined TODO tags in use within the project.
  1. **Issue Resolution:** For each identified TODO, analyze the context and either
     resolve the underlying task or clarify/update the comment.
  1. **Output Report:** Provide a report of found TODOs and actions taken.

## Workflow: Print Focused File (p)

- **Purpose:** Prints the content of the currently focused file within a code block.
- **Usage:** `p`
- **Actions:**
  1. **Context Check:** Identify the currently focused file.
  1. **File Read:** Read the content of the identified file.
  1. **Output Display:** Display the file content within a formatted code block.

## Workflow: Refactor Code (`refactor`)

- **Purpose:** Ensures one or more specified files comply with Kingarrrt Engineering Standards.
- **Usage:** `refactor [file_path...]` (Current working directory implied if no path specified.)
- **Actions:**
  1. **Identify Files:** Determine target files.
  2. **Apply Standards:** Modify files to comply with Kingarrrt Engineering Standards.
  3. **Report Changes:** Present a diff of modifications.

## Workflow: Reread Standards (R)

- **Purpose:** Re-reads the `artstd/README.md` document and applies all standards
  defined within it.
- **Usage:** `R`
- **Actions:**
  1. **File Read:** Read the content of `artstd/README.md`.
  1. **Standards Parse:** Parse and interpret all standards, principles, and command
     definitions.
  1. **Internal Application:** Apply all parsed standards to the agent's operational
     guidelines and behavior.
  1. **Confirmation:** Confirm to the user that the standards have been re-read and
     applied.
  1. **Compliance:** All applicable files that were part of the last interaction or task
     performed MUST be modified to comply with the newly re-read and applied standards.

## Workflow: Reset Context (r)

- **Purpose:** Resets the current conversational context of the agent. This clears
  previous turns, memory, and task states.
- **Usage:** `r`
- **Actions:**
  1. **Context Clear:** Clear all stored conversational context, including previous
     turns, short-term memory, and any active task states (e.g., todos).
  1. **Confirmation:** Confirm to the user that the context has been reset.

## Workflow: Review Code (`review`)

- **Purpose:** Reviews one or more specified files for compliance with the Kingarrrt
  Engineering Standards.
- **Usage:** `review [file_path...]` (If no file_path is specified, the current working
  directory is implied.)
- **Actions:**
  1. **File Identification:** Identify the target files for review based on arguments or
     implied directory.
  1. **Standards Check:** Evaluate the identified files against the Kingarrrt
     Engineering Standards (e.g., formatting, style, architectural patterns,
     documentation).
  1. **Report Non-compliance:** Report any deviations or non-compliance found, providing
     specific details and suggestions for correction.

## Workflow: Toggle Push (P)

- **Purpose:** Toggles the "Push" mode, which determines if commits are
  automatically pushed to the remote repository.
- **Usage:** `P`
- **Actions:**
  1. **Mode Toggle:** Toggle the internal state of the push mode.
  1. **Push Local Commits:** If the mode is toggled to "enabled", the assistant MUST
     immediately push all unpushed local commits to the remote repository.
  1. **Confirmation:** Confirm the new state (enabled/disabled) to the user.

## Workflow: Toggle Diff Display (d)

- **Purpose:** Toggles the display format of responses between unified diff blocks and
  regular output mode.
- **Usage:** `d`
- **Actions:**
  1. **State Check:** Determine the current response display mode.
  1. **Mode Toggle:** Switch the response display mode to the alternative (diff to
     regular, or regular to diff).
  1. **Confirmation:** Confirm the new display mode to the user.

## Workflow: View Focused File (v)

- **Purpose:** Displays the content of the currently focused file in a rendered,
  prose-like view, suitable for human readability.
- **Usage:** `v`
- **Actions:**
  1. **Context Check:** Identify the currently focused file.
  1. **File Read:** Read the content of the identified file.
  1. **Rendering:** Render the file content into a human-readable, prose format.
  1. **Output Display:** Display the rendered view to the user.