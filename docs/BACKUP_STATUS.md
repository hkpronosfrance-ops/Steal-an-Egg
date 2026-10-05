# Backup status

## Backed up in GitHub

- 89/89 Luau source files under `src/`
- project README and changelog
- architecture, DataStore, security and localization documentation
- source inventory
- known issues
- class counts
- script metadata
- special-instance metadata
- source byte manifest
- Roblox asset-ID inventory
- SHA-256 checksums for all three RBXL snapshots
- Git LFS rules for Roblox binary files

## RBXL snapshots

Expected binary snapshots:

| File | Size (bytes) | SHA-256 |
|---|---:|---|
| `stealanegg14.rbxl` | 34,944,300 | `9a6ff179f37388b6e03abca421c8f3343431991f5516cc0d8f2eaf6edac8abd3` |
| `stealanegg14_EN_FR.rbxl` | 34,962,917 | `ce8d0606b357d76a1396c5636aa902e085c05194b31f87674540461fa76ba700` |
| `stealanegg14_EN_FR_COMPLETE.rbxl` | 34,968,802 | `5e25c079a63e154e3f0b8d0e780c7c048d548f82262559910864e40d5c4519c9` |

These binary files are not yet stored in the Git repository. The connected GitHub API available in this workspace can create/update UTF-8 repository files but cannot stream local 35 MB binary files or Git LFS objects.

Before publishing purchased pack binaries/assets, verify that the pack license allows public redistribution. Prefer a private repository for full-source backups.
