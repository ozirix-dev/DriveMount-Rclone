# Migration from old location

## Old source

- the previous local-only mount project tree

## What was migrated

- the rclone WebDAV serving idea
- the `Z:` WebDAV mapping model
- the core runtime sequence
- practical troubleshooting notes
- a cleaner start wrapper

## What was intentionally not migrated

- old log files
- old scheduled task definitions
- any machine-local auth material
- the old emoji-named doc file as-is

## Normalized documentation

The old note file with the emoji-heavy name has been replaced by normal repo docs:

- `docs\architecture.md`
- `docs\setup-and-usage.md`
- `docs\tasks-plan.md`
- `docs\known-risks-and-open-questions.md`

## Weirdness found

- the old material was coherent about `Z:`, not `X:`
- the old flow had a gap between serving WebDAV and mapping the drive
- the previous setup relied on a mix of wrapper scripts and a task that did not clearly cover the map step
- the old scripts resolved `rclone.exe` from PATH, which is acceptable for V1 but worth hardening later

## Assumptions carried forward

- `Z:` remains the active V1 drive letter
- `localhost:8080` remains the WebDAV endpoint for V1
- the existing remote name remains `rclone-google:`
- Windows WebClient/WebDAV is still the mapping layer

## Still needs live verification later

- whether the local rclone config remains valid after future machine changes
- whether `localhost:8080` should stay fixed or become configurable
- whether `rclone.exe` should be path-pinned later
