# AIOS — Personal AI Engineering Operating System

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-v1.3.1-green)]()
<br>[中文](README.zh-CN.md)

AIOS transforms your AI coding agent from a forgetful assistant into a disciplined engineering collaborator. It combines the **skill chain** pattern from [Superpowers](https://github.com/obra/superpowers) with the **spec/change management** system from [OpenSpec](https://github.com/Fission-AI/OpenSpec), augmented with 100 actionable engineering rules based on OWASP, Google Code Review, and language community standards.

---

## Table of Contents

- [Why AIOS](#why-aios)
- [Quick Start](#quick-start)
- [How It Works](#how-it-works)
- [Skills](#skills)
- [Project Structure](#project-structure)
- [Rules System (100 Rules)](#rules-system-100-rules)
- [Preset Profiles](#preset-profiles)
- [CLI Commands](#cli-commands)
- [Coexistence with Other Skill Packs](#coexistence-with-other-skill-packs)
- [Design Principles](#design-principles)
- [Installation Reference](#installation-reference)
- [License](#license)

---

## Why AIOS

AI coding assistants are powerful but unreliable without constraints. They forget project context between sessions, skip testing, generate insecure code, and lack a consistent engineering process.

AIOS solves this by injecting **memory, rules, and process** into every session:

- **Memory** — `ai/state/` remembers project focus, tasks, and roadmap across sessions
- **Rules** — 100 enforcement rules (L1 red lines, L2 architecture, L3 style) constrain every code action
- **Process** — An 8-skill chain enforces design-before-code, test-before-implement, review-before-done
- **Personalization** — `ai/config.yaml` captures your naming conventions, code style, commit format, and test framework
- **Safety** — 8 L1 red lines prevent dangerous operations (git push, destructive commands, secret leakage)
- **Coexistence** — Detects other skill packs (Superpowers, OpenSpec, etc.) and offers standalone/complementary modes

---

## Quick Start

### 1. Install

**Claude Code (marketplace):**
```bash
/plugin marketplace add alex-hlh/aios-marketplace
/plugin install paios@aios-marketplace
```

**OpenCode (plugin):**
```json
{ "plugin": ["paios@git+https://github.com/alex-hlh/Paios.git"] }
```

**npm (for CLI tool):**
```bash
npm install -g @huahu/paios
paios install
```

### 2. Initialize your project

**Automatic (recommended):** After installing the AI tool plugin, restart. `pai:bootstrap` detects the missing `ai/` directory and offers to initialize — just answer a few questions and AI does the rest.

**npx / CLI (for CI/CD or batch setup):**
```bash
npx @huahu/paios init                  # Interactive
npx @huahu/paios init --defaults       # All defaults
npx @huahu/paios init --tech node,react
npx @huahu/paios status
npx @huahu/paios update
```

**Global install:**
```bash
npm install -g @huahu/paios
paios init
```

**Retrofit an existing project:** Run `pai:retro` to auto-detect tech stack, code style, commit conventions from your existing code, then generate `ai/` without touching your code:

```
You: "/pai:retro"
AI:  [pai:retro] Scanning project...
     Detected: Node.js + TypeScript, viTest, 2-space indent, single quotes
     Confirm? [Y/n]
     ✓ ai/ generated (92 rules, config matched to your existing style)
```

### 3. Start coding

Restart your AI tool. On the next session, `pai:bootstrap` auto-activates, loads your project state, injects 100 rules, and declares the skill chain. Just describe what you want to build.

```
You: "Add user login with JWT"
AI:  [pai:bootstrap] AIOS Ready. Platform: OpenCode, Mode: standalone, Rules: 100 loaded.
     [pai:design] Q1: What authentication method would you prefer? [JWT / Session / OAuth / Other]
     ... design discussion ...
     ✓ ai/changes/add-login/proposal.md
     ✓ ai/changes/add-login/design.md
     Ready for spec generation!

You: "Looks good, generate the spec"
AI:  [pai:spec] Delta spec created: 3 ADDED requirements, 0 MODIFIED, 0 REMOVED.
     ✓ 8 tasks generated (1.1 - 3.2)
     Ready for implementation!

You: "Let's build it"
AI:  [pai:build] Task 1.1: Create User model test
     [RED]    Write test → Run → FAIL ✓
     [GREEN]  Minimal impl → Run → PASS ✓
     [REFACTOR] Cleanup → PASS ✓
     [pai:review] Completeness: OK | Correctness: OK | Compliance: OK
     ... (7 more tasks) ...
     All tasks complete!

You: "Archive this change"
AI:  [pai:done] Tests: 23/23 PASS. No conflicts. Merged specs ✓.
     Git hint: git commit -m "feat(auth): add JWT user login"
     [pai:reflect] Process: clean. Skill suggestions: none.
      Change archived. Ready for next feature!
```

You can also use individual skills without the full chain:
```
You: "/pai:debug"
AI:  [pai:debug] Step 1: REPRODUCE → Step 2: LOCATE → Step 3: FIX → Step 4: VERIFY

You: "/pai:review"
AI:  [pai:review] Reviewing current diff... Critical: 0, Warning: 1, Pass: 5
```

---

## How It Works

```
pai:bootstrap → pai:design → pai:spec → pai:build → (pai:debug / pai:review) → pai:done → pai:reflect
```

On every session start, `pai:bootstrap` runs a 10-step startup sequence:

1. **Environment Scan** — Detects conflicting skill packs (Superpowers, OpenSpec, etc.), lets you choose mode
2. **L1 Red Lines** — Injects 8 non-negotiable safety rules as permanent background instructions
3. **Platform Detection** — Maps tool names for the current environment (OpenCode / Claude Code)
4. **Red Flags Table** — Injects 12 anti-rationalization patterns ("This is too simple to need a skill" → "Check anyway")
5. **Pressure Test** — Injects adversarial scenarios to harden process compliance
6. **Version Check** — Warns if `ai/.version` is out of sync with the installed skill pack
7. **Project State** — Reads `ai/state/`, `ai/config.yaml`, `ai/memory/glossary.yaml`
8. **Rules Injection** — Scans all `ai/rules/*.yaml` (including `custom/`) and injects as background constraints
9. **Config Injection** — Injects code conventions (indent, quotes, naming, test framework, commit style)
10. **Skill Chain Declaration** — Registers the automatic trigger rules for the 8-skill chain

Three coexistence modes handle other skill packs automatically:

| Mode | Behavior |
|------|----------|
| **standalone** | AIOS takes full control. Complete skill chain + all rules active. |
| **complementary** | AIOS injects rules + state + config only. Other skill packs drive the workflow. |
| **ask** (default) | Detects conflicts and lets you choose. Choice is persisted to `ai/config.yaml`. |

---

## Skills

| Skill | Trigger | What It Does |
|-------|---------|--------------|
| **pai:bootstrap** | Session start (auto) | 10-step startup: env scan, L1 rules, platform mapping, Red Flags, pressure test, version check, **auto-init if needed**, state load, 100 rules injection, config injection, skill chain declaration |
| **pai:prd** | "帮我写 PRD" / "/pai:prd" | 7-stage structured PRD: problem → personas → journey → MoSCoW → NFR → milestones → risks. Produces `prd.md` + `personas.md`. |
| **pai:story** | "出原型" / "/pai:story" | 5-step requirements analysis: prototype ASCII wireframes → data flows → backend flows → API list → feature points. Outputs 5 `docs/*.md` files. Connects PRD to design. |
| **pai:retro** | "aios retro" / "analyze project" | Reverse-engineers an existing project. Scans code/style files → auto-detects tech stack, conventions → generates `ai/` without modifying code. |
| **pai:init** | Manual trigger or bootstrap redirect | Interactive project initialization. Select preset → confirm defaults → generates entire `ai/` directory. Same logic as bootstrap auto-init. |
| **pai:design** | "Add / build / design / implement X" | Explores project context → asks 5-dim mandatory questions → proposes 2-3 approaches → presents design with ASCII diagrams → writes proposal + design. **No code before approval.** |
| **pai:amend** | "还要加" / "需求变了" / "/pai:amend" | Scope change entry point. Detects current change state → analyzes relationship → recommends strategy (append/new/defer) → coordinates document updates. |
| **pai:spec** | Design approved | Reads current specs → generates delta spec (ADDED/MODIFIED/REMOVED) → generates tasks.md (2-5 min) → writes timestamp |
| **pai:build** | Tasks ready, user confirms | Strict RED-GREEN-REFACTOR TDD cycle per task. Follows project conventions (indent, quotes, naming, test framework). Each task completion triggers `pai:review`. **Tests before implementation, always.** |
| **pai:debug** | Test failure / runtime error / bug report | 4-step systematic debugging: Reproduce → Locate root cause (binary search, no guessing) → Propose fix → Fix + verify. Optionally records anti-pattern to `ai/memory/anti-patterns.md`. |
| **pai:review** | After each task complete | 3D code review: Completeness (vs spec scenarios), Correctness (logic + edge cases + security), Compliance (100 rules across L1/L2/L3). Outputs Critical/Warning/OK classification. Critical issues block progress. |
| **pai:done** | All tasks complete | Runs full test suite → conflict detection (checks if other unarchived changes touch same specs) → merges delta specs → archives change → updates state → generates git commit hint (Conventional Commits format) → triggers `pai:reflect` |
| **pai:reflect** | After archive | Reviews the completed change cycle: Were there process deviations? Unexpected situations? Skill instruction improvements needed? Writes findings to `ai/memory/decisions.md`. |

---

## Project Structure

```
your-project/
├── ai/                              # AI context (created by `aios init`)
│   ├── config.yaml                  # Personal config: conventions, naming, testing, AIOS behavior
│   ├── .version                     # AIOS version marker (for update detection)
│   ├── state/                       # Current work context
│   │   ├── current.md               #   Active change, sprint focus, blockers, next actions
│   │   ├── tasks.md                 #   Kanban board: IN_PROGRESS / TODO / DONE
│   │   └── roadmap.md              #   Version roadmap
│   ├── memory/                      # Long-term project memory
│   │   ├── decisions.md             #   Tech decisions + pai:reflect retrospectives
│   │   ├── anti-patterns.md         #   Forbidden patterns learned from bugs
│   │   └── glossary.yaml           #   Unified project terminology
│   ├── rules/                       # 100 engineering rules (auto-scanned by paibootstrap)
│   │   ├── hard-rules.yaml          #   L1: Project-level red lines
│   │   ├── arch-rules.yaml          #   L2: Architecture constraints (14 rules)
│   │   ├── security-rules.yaml      #   L2: OWASP security (10 rules)
│   │   ├── error-rules.yaml         #   L2: OWASP error handling (7 rules)
│   │   ├── logging-rules.yaml       #   L2: OWASP logging (9 rules)
│   │   ├── api-rules.yaml           #   L2: REST API design (8 rules)
│   │   ├── git-rules.yaml           #   L2: Git & commits (6 rules)
│   │   ├── style-rules.yaml         #   L3: Code style (16 rules)
│   │   ├── test-rules.yaml          #   L3: Testing standards (10 rules)
│   │   └── custom/                  #   Your own rules (any .yaml, auto-scanned)
│   ├── specs/                       # System behavior specs (source of truth)
│   │   └── <domain>/spec.md         #   Requirements + Given/When/Then scenarios
│   ├── changes/                     # Active change proposals
│   │   └── <change-name>/
│   │       ├── proposal.md          #   Intent + scope + approach
│   │       ├── design.md            #   Technical design + architecture decisions
│   │       ├── tasks.md             #   Implementation checklist
│   │       ├── .openspec.yaml       #   Change timestamp (for conflict detection)
│   │       └── specs/<domain>/      #   Delta specs (ADDED/MODIFIED/REMOVED)
│   └── changes/archive/             # Completed changes (preserved for audit)
│       └── <date>-<change-name>/
```

### `ai/config.yaml` Reference

```yaml
project:
  name: "MyApp"
  description: "Online collaboration platform"
  preset: "node-typescript"

conventions:
  git:
    commit_style: conventional      # Conventional Commits 1.0.0
    branch_naming: "feature/<name>"
  code:
    indent: 2                       # Spaces
    quotes: double
    semicolons: true
    trailing_commas: all
    max_line_length: 80
  naming:
    files: kebab-case
    functions: camelCase
    classes: PascalCase
    constants: UPPER_SNAKE_CASE
    variables: camelCase

testing:
  framework: vitest
  coverage_threshold: 80

aios:
  strict_mode: true                 # Refuse on L1/L2 violations
  coexistence_mode: ask             # ask | standalone | complementary
  language: zh-CN
```

---

## Rules System (100 Rules)

All rules are automatically loaded by `pai:bootstrap` and enforced by `pai:review`. Rules in `ai/rules/custom/` are auto-scanned — add any `.yaml` file there.

### L1 — Red Lines (8 rules, global)
*Non-negotiable. Violations are BLOCK_AND_WARN.*

| ID | Rule |
|----|------|
| H001 | No git push/merge/rebase/deploy without human confirmation |
| H002 | No destructive commands (DROP TABLE, rm -rf, DEL /F) |
| H003 | No hardcoded secrets, keys, or tokens in code/logs/config |
| H004 | All AI-generated code requires human code review before merge |
| H005 | No access to files outside the current task scope |
| H006 | No system-level package installs without explicit user approval |
| H007 | Use audited crypto libraries only (bcrypt/scrypt/argon2, AES-GCM) |
| H008 | Server-side input validation mandatory; allowlist over denylist |

### L2 — Architecture & Domain (54 rules)
*Design and structural constraints. AUTO-APPLIED based on project scope (backend/api/web).*

| File | Rules | Scope | Source |
|------|-------|-------|--------|
| `arch-rules.yaml` | 14 | backend/api/web/all | Layered architecture, transactions, circuit breaker, RESTful design, pagination, rate limiting, idempotency, auth |
| `security-rules.yaml` | 10 | backend/web/all | OWASP: input validation, XSS, SQL injection, password hashing, deserialization, file upload, redirects, CSRF, dependencies, client-side storage |
| `error-rules.yaml` | 7 | backend/api | OWASP: global error handler, status codes, message sanitization, RFC 7807, specific exceptions, async error handling |
| `logging-rules.yaml` | 9 | backend/all | OWASP: security event logging, log format (ISO 8601), data exclusion, log injection prevention, log levels, trace IDs |
| `api-rules.yaml` | 8 | api | RESTful: noun resources, kebab-case paths, versioning, pagination, envelope format, status codes, rate limiting, sparse fieldsets |
| `git-rules.yaml` | 6 | all | Conventional Commits format, breaking change markup, branch naming, single logical unit per commit |

### L3 — Style & Testing (26 rules)
*Code quality and testing standards. Warnings, non-blocking except REVIEW_BLOCK items.*

| File | Rules | Focus |
|------|-------|-------|
| `style-rules.yaml` | 16 | Comments (explain why), types (no any/Object), structured logging (no print), exception handling (no empty catch), naming conventions, function length (max 50 lines), nesting depth (max 3), no magic numbers, max 5 params per function, boolean params, early return, immutability, DRY principle, config extraction |
| `test-rules.yaml` | 10 | Coverage threshold, integration tests per endpoint, AAA pattern, mock external services, TDD cycle enforced, test naming standards, regression tests required, test isolation, no flaky tests, behavior over implementation testing |

### Enforcement Levels

| Level | Behavior | Used By |
|-------|----------|---------|
| **BLOCK_AND_WARN** | Refuse execution, warn user | L1 red lines, critical L2 rules |
| **REVIEW_BLOCK** | Must fix in review before continuing | Commit format, coverage, log compliance |
| **REFACTOR_SUGGESTION** | Strong suggestion, record warning | Architecture deviations |
| **REVIEW_SUGGESTION** | Record in review, allow continue | Nice-to-have improvements |
| **WARN** | Warn but don't block | Code style deviations |
| **STYLE** | Advisory only | Naming, formatting preferences |
| **AUDIT_ONLY** | Record for human review | Process compliance (e.g., code review before merge) |

---

## Preset Profiles

`aios init` automatically applies a profile based on your tech stack. Profiles are based on each language community's de facto standard tool defaults:

| Preset | Indent | Quotes | Semicolons | Line Len | File Naming | Func Naming | Test | Source |
|--------|--------|--------|------------|----------|-------------|-------------|------|--------|
| **node-typescript** | 2 sp | double | yes | 80 | kebab-case | camelCase | vitest | [Prettier 3.x](https://prettier.io/docs/en/options.html) |
| **python** | 4 sp | double | — | 88 | snake_case | snake_case | pytest | [PEP 8](https://peps.python.org/pep-0008/) + [black](https://black.readthedocs.io/) |
| **go** | tabs | double | — | none | snake_case | camelCase | go test | [Effective Go](https://go.dev/doc/effective_go) + `gofmt` |
| **rust** | 4 sp | double | yes | 100 | snake_case | snake_case | cargo test | [Rust Style Guide](https://doc.rust-lang.org/nightly/style-guide/) + `rustfmt` |
| **java** | 4 sp | double | yes | 120 | PascalCase | camelCase | junit | Google Java Style + Checkstyle |
| **universal** | 2 sp | double | no | 100 | kebab-case | camelCase | generic | (sensible defaults) |

To customize: edit `ai/config.yaml` after init, or answer the interactive prompts during `aios init`.

---

## CLI Commands

```bash
# Interactive initialization
npx @huahu/paios init
npx @huahu/paios install
npx @huahu/paios status
npx @huahu/paios init --defaults
npx @huahu/paios init --preset python --name "MyAPI"
```

### `npx paios init` Interactive Flow

```
$ npx @huahu/paios init

  Primary language [node/python/go/rust/java/universal]: node
  Preset: node-typescript

  Project name [my-project]:
  Description:

  --- Press Enter to accept defaults ---
  Commit style [conventional]:
  Branch naming [feature/<name>]:
  Indent size [2]:
  Quote style [double/single]: double
  Semicolons [true/false]: true
  Max line length [80]:
  File naming [kebab-case]:
  Function naming [camelCase]:
  Test framework [vitest]:
  AI output language [zh-CN/en]: zh-CN
  Strict mode [true/false]: true

  Generating config files...
    ai/config.yaml
    ai/.version
    ai/state/ (3 files)
    ai/memory/ (3 files)
    ai/rules/ (10 files)
    ai/specs/, ai/changes/ (created)

  AIOS init complete!
```

### `aios status` Output

```
======== AIOS Project Status ========
  AIOS version: v1.0.0 (current: v1.0.0)
  Project: MyApp
  Preset: node-typescript
  Current Change: add-user-login
  Last updated: 2026-05-16

  Active Changes:
    - add-user-login
```

---

## Coexistence with Other Skill Packs

AIOS is designed to work alongside other skill packs and IDEs. It detects conflicts and lets you choose the operating mode.

### Detection

At session start, `pai:bootstrap` scans for:

1. **Overlapping skills** across 7 domains: requirements/design, task planning, TDD/testing, debugging, code review, archiving, git workflows
2. **Project traces** such as `openspec/` or `docs/superpowers/specs/` directories

### Resolution

If conflicts are detected and `coexistence_mode` is `ask` (default), you'll see:

```
[AIOS] Detected possible conflicting skill packs:
  Skill overlap: brainstorming (Superpowers) ←→ pai-design (AIOS)
  Project traces: openspec/ directory

Choose coexistence mode:
  A) AIOS standalone (ignore others)
  B) Complementary (AIOS provides rules only, others drive workflow)
  C) Disable AIOS skill chain this session (rules only)
```

Your choice is saved to `ai/config.yaml` for future sessions.

### Complementary Mode

In complementary mode, AIOS acts as a **background rules engine**:

- All 100 rules are injected and enforced
- Code conventions are applied to every code action
- L1 red lines protect against dangerous operations
- Skill chain is NOT injected — your other skill pack drives the workflow

---

## Design Principles

| Principle | Implementation |
|-----------|---------------|
| **Skill chain over ad-hoc** | Every change follows a proven 8-skill process |
| **Evidence over claims** | Tests pass before claiming done; verify before archiving |
| **Red lines never off** | L1 safety rules persist across ALL sessions regardless of mode |
| **Plan then build** | Design approval gate prevents premature implementation |
| **Memory over amnesia** | `ai/state/` and `ai/memory/` maintain project context across sessions |
| **Constraints as guardrails** | 100 rules prevent common mistakes; strict mode blocks violations |
| **Personalization over dogma** | `ai/config.yaml` captures YOUR conventions, not someone else's |
| **Coexistence over lock-in** | Detects other tools, offers complementary mode, never forces a choice |
| **Platform independence** | Same skills work on OpenCode, Claude Code, and any future platform via `tool-map.yaml` |
| **Iterative improvement** | `pai:reflect` captures lessons learned; `aios update` adds new rules over time |

---

## Installation Reference

### Quick install

```bash
# CLI tool
npm install -g @huahu/paios

# Register with OpenCode (auto-detect)
paios install

# Claude Code (marketplace)
/plugin marketplace add alex-hlh/aios-marketplace
/plugin install paios@aios-marketplace
```

To pin a version:
```json
{ "plugin": ["aios@git+https://github.com/alex-hlh/Paios.git#v1.0.0"] }
```

**Windows:** If git-backed plugin install fails, use npm:
```powershell
npm install Paios@git+https://github.com/alex-hlh/Paios.git --prefix "$HOME\.config\opencode"
```
Then in `opencode.json`: `{ "plugin": ["~/.config/opencode/node_modules/Paios"] }`

### Claude Code

Register the marketplace and install:
```bash
/plugin marketplace add alex-hlh/aios-marketplace
/plugin install paios@aios-marketplace
```

## Acknowledgments

AIOS builds on the ideas and patterns of several groundbreaking projects:

- **[Superpowers](https://github.com/obra/superpowers)** by Jesse Vincent — The skill chain pattern (brainstorm → plan → build → review → finish) that inspired our 8-skill workflow. The Red Flags anti-rationalization table, adversarial pressure testing, and "skills as mandatory" philosophy come directly from Superpowers' battle-tested approach.

- **[OpenSpec](https://github.com/Fission-AI/OpenSpec)** by Fission AI — The spec/change management model (specs as source of truth, changes as delta proposals, archive workflow) and the OPSX fluid actions paradigm shaped our `pai:spec` and `pai:done` skills.

- **[OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/)** — Our security, error handling, and logging rules (27 rules) are derived from OWASP's authoritative guidance on input validation, XSS prevention, SQL injection, password storage, error handling, logging, and file upload security.

- **[Google Code Review Standards](https://google.github.io/eng-practices/)** — The 3D review model (completeness, correctness, coherence) and style guidelines (function length, naming, comments) are adapted from Google's engineering practices.

- **[Conventional Commits](https://www.conventionalcommits.org/)** — v1.0.0 specification for structured commit messages.

- **[Prettier](https://prettier.io/)** / **[PEP 8](https://peps.python.org/pep-0008/)** / **[Effective Go](https://go.dev/doc/effective_go)** / **[Rust Style Guide](https://doc.rust-lang.org/nightly/style-guide/)** — Each preset profile is based on the de facto standard formatting tool or style guide of its language community.

## License

MIT © 2026 Paios

Based on patterns from [Superpowers](https://github.com/obra/superpowers) (MIT) and [OpenSpec](https://github.com/Fission-AI/OpenSpec) (MIT), with security rules derived from [OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/) (CC BY-SA 4.0).
