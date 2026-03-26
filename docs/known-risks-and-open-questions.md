# Known risks and open questions

## Risks

- `rclone.exe` is still resolved from `PATH` in V1.
- `localhost:8080` is still a fixed assumption.
- `Z:` is still hard-coded as the V1 drive letter.
- The local remote config is machine-specific and lives outside git.

## Open questions

- Should `rclone.exe` be path-pinned later?
- Should `localhost:8080` become configurable later?
- Should `Z:` remain locked, or should the project support a configurable drive letter later?
- Is there any future need for `X:` compatibility or an alias?

## Live verification still needed

- confirm the wrapper behaves the same after a fresh logon
- confirm Explorer sees the mapping consistently in both normal and elevated contexts
- confirm the local rclone config survives future machine changes
- confirm the logs stay readable after repeated runs
