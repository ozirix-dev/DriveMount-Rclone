[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseBOMForUnicodeEncodedFile', '', Justification = 'Repository files are kept in the existing UTF-8 encoding style.')]

param(
  [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"

Push-Location $RepoRoot
try {
  & npx --yes markdownlint-cli2
  if ($LASTEXITCODE -ne 0) {
    throw "markdownlint-cli2 failed with exit code $LASTEXITCODE"
  }
}
finally {
  Pop-Location
}
