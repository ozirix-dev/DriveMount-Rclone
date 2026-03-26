# Known risks and open questions

## Current behavior

- `scripts\DriveMount-Rclone.common.ps1` is the source of truth for the current runtime defaults.
- `rclone.exe` resolves from `PATH` or known local install locations.
- The default listener is `127.0.0.1:8080`.
- The default WebDAV URL is `http://localhost:8080/`.
- The default mapped drive is `Z:`.
- The expected mapped UNC root is `\\localhost@8080\DavWWWRoot`.
- The local remote config is machine-specific and lives outside git.
- The repo does not store Google credentials, tokens, or its own auth layer.
- Listener checks now verify that the port owner matches the expected project `rclone serve webdav` command line before stop/test actions proceed.

## Open questions

- Should `rclone.exe` be path-pinned later?
- Should `localhost:8080` become configurable later?
- Should `Z:` remain locked, or should the project support a configurable drive letter later?
- Is there any future need for `X:` compatibility or an alias?
- Should remote re-auth stay manual or get a separate local-only helper in a later round?

## Live verification still needed

- confirm the wrapper behaves the same after a fresh logon
- confirm Explorer sees the mapping consistently in both normal and elevated contexts
- confirm the local rclone config survives future machine changes
- confirm the logs stay readable after repeated runs
