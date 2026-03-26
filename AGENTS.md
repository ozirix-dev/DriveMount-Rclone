# AGENTS.md

This repository is a Windows infra and automation project, not an application repo.

## Working rules

- Read the docs before editing scripts.
- Prefer the smallest working change that improves the stack.
- Keep PowerShell as the default operating model.
- Keep `start-z-drive.ps1` as the preferred operator entrypoint.
- Keep docs aligned with script behavior when behavior changes.
- Do not modify real scheduled tasks without explicit user approval.
- Do not perform destructive file cleanup outside an isolated test folder.
- Do not print, commit, or store secrets, tokens, or credential material.
- Prefer wrapper-based orchestration over scattered manual steps.
- Keep drive-letter and port assumptions documented near the top of scripts.

## Scope discipline

- Stay inside the repository root unless the user explicitly asks for a wider audit.
- Do not touch the old local source tree except for read-only comparison if needed.
- Do not touch other project workspaces.
- Do not introduce extra abstraction layers unless they clearly reduce risk or duplication.

## Verification

- Use lightweight, local verification only.
- Prefer script syntax checks and status checks over runtime side effects.
- If runtime verification is needed, keep it read-only or explicitly non-destructive.

## Logging

- Treat `logs\` as machine-local runtime output.
- Do not commit log files.
- Document troubleshooting steps that explain why `Z:` might not appear.
