# Documentation Guidelines

## Purpose

Keep project documentation short, accurate, and easy to load into working context.

## Mandatory Rules

- `README.md` is the public, user-facing entrypoint
- detailed operational docs live in `docs/`
- files inside `docs/` are optimized for maintainers and coding agents
- one topic or project area per document
- each document must stay below `250` Markdown lines
- prefer links to real source files over copying long config blocks
- commands, paths, env vars, Make targets, and workflow names must match the repo exactly
- if a document conflicts with implementation, the document must be updated in the same change
- root docs such as `README.md`, `ARCHITECTURE.md`, and `VIKUNJA_BOOTSTRAP.md` should stay short and point to the focused docs

## Preferred Document Shape

- `Purpose`
- `Relevant Files`
- `Commands` or `Procedure`
- `Checks`
- `Related Docs`

## Required Review After Every Implementation Or Fix

A documentation review round is part of the done criteria for every implementation, fix, or operational change.

Run this review after the change:

1. Identify the user-visible or operator-visible behavior that changed.
2. Search the docs for affected commands, paths, env vars, workflow names, ports, domains, and filenames.
3. Update or remove outdated text in the same change.
4. Re-check examples against the real `Makefile`, `docker/*`, `.github/workflows/*`, and `.env.example` files.
5. Confirm each touched document is still focused and stays below `250` lines.
6. If no doc changes are needed, explicitly confirm that the review was completed and the docs remain current.

## Good Practices

- link to the authoritative file instead of restating large configs
- keep procedures step-based and operational
- separate local, production, CI/CD, and recovery guidance into different files
- document current behavior, not planned behavior that is not implemented yet
- keep `README.md` approachable for new users and keep `docs/` reference-oriented

## Things To Avoid

- oversized catch-all documents
- duplicated command lists across many files
- stale references to renamed Make targets or workflow files
- planning notes presented as if they are already implemented

## Related Docs

- `README.md`
- `docs/README.md`
