# Security

This repository is infrastructure automation, not a credential store.

## Do not commit

- Google credentials
- account tokens and refresh material
- API keys and sensitive client material
- private keys
- the local rclone config file

## Logs

- `logs\` is machine-local runtime output and is ignored by git.
- Logs may contain local environment details.
- Review logs before sharing them publicly.

## Reporting issues

- Report security issues responsibly.
- Do not paste sensitive auth material or full auth dumps into issues or commits.
- If a fix needs local auth state, keep it machine-local and out of the repo.
