---
title: Documentation Index
description: Map of the unifi2mqtt documentation set and the front matter convention used for agent-readable Markdown files.
audience:
  - agents
  - maintainers
status: current
front_matter_schema:
  required:
    - title
    - description
    - audience
    - status
  optional:
    - related
    - source_landmarks
    - commands
related:
  - ../README.md
  - ARCHITECTURE.md
  - OPERATIONS.md
  - AGENT_GUIDE.md
---

# Documentation Index

This project keeps GitHub-facing overview material in `README.md` as plain Markdown. Files under `docs/` are front matter Markdown files so agents can discover purpose, scope, and related source files before loading full document bodies.

## Front Matter Convention

Every Markdown file in `docs/` should start with YAML front matter:

```yaml
---
title: Short Human Title
description: One sentence describing when this file is useful.
audience:
  - agents
  - maintainers
status: current
related:
  - ../Package.swift
---
```

Use `related` for nearby documentation or important source files. Use `source_landmarks` when the document is mainly a navigation file for code. Use `commands` when the document gives runnable commands.

`README.md` is the exception. It intentionally has no front matter because GitHub project READMEs serve human users directly and should render as simple Markdown.

## Files

- `ARCHITECTURE.md`: package structure, executable responsibilities, and runtime data flow.
- `OPERATIONS.md`: build, run, configuration, container, and verification commands.
- `AGENT_GUIDE.md`: repo navigation and change guidelines for coding agents.

## Maintenance Rules

When adding project documentation:

1. Put agent-oriented documentation under `docs/`.
2. Include YAML front matter with at least `title`, `description`, `audience`, and `status`.
3. Keep the README plain Markdown and link to structured docs instead of duplicating detailed agent guidance.
4. Prefer stable source paths in `related` and `source_landmarks` so agents can jump directly to the right code.
