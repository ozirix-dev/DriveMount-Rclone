# AGENTS.md

This repository is a Windows infra and automation project, not an application repo.

## Root-level defaults

- Also read `D:\Projects\_Hub\Master\AGENTS.md` when a task touches cross-repo workflow, shorthand commands, shared local security practice, or Cloudflare authority.
- Treat the following root-level rules as active here too unless this repo file is stricter:
  - `c` = commit, `p` = push, `r` = add/update ReportHub, `cpr` = commit + push + report for the current repo task
  - run a ReportHub pass after larger work without needing a separate prompt
  - Cloudflare has standing permission for scoped non-destructive read/write work; ask before destructive or hard-to-reverse changes
  - secrets belong in the `K:\` vault by default, not in repo trees or temporary work areas
- If `D:\Projects\_Hub\Master\AGENTS.md` and this repo file differ, follow the stricter rule and keep DriveMount-Rclone-specific infra and safety rules authoritative for this repo.

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
- Do not touch the previous source tree except for read-only comparison if needed.
- Do not touch other project workspaces.
- Do not introduce extra abstraction layers unless they clearly reduce risk or duplication.

## Verification

- Use lightweight, local verification only.
- Prefer script syntax checks and status checks over runtime side effects.
- If runtime verification is needed, keep it read-only or explicitly non-destructive.

## File safety

- Do not delete files, folders, or other local artifacts without explicit user confirmation.
- Before any destructive removal, ask for confirmation in a clear yes/no form.
- Only proceed with deletion after the user has explicitly answered `Kyllä`.

## Logging

- Treat `logs\` as machine-local runtime output.
- Do not commit log files.
- Document troubleshooting steps that explain why `Z:` might not appear.

