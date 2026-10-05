# Backup status

## GitHub backup

Current repository state includes:

- **89/89 Luau sources**
- Rojo project definition
- EN/FR localization catalog
- localization patch/rebuild tools
- RBXL parser/inspection tools
- architecture/economy/security/DataStore/remote/monetization docs
- release checklist
- source inventory and byte manifest
- Asset ID inventory
- complete/current property metadata audit
- original audit metadata
- raw RBX inspection data and reconstructible tree dump
- final extraction inventory with size + SHA-256

## Roblox place snapshots

The three local place snapshots are:

| File | Size (bytes) | SHA-256 |
|---|---:|---|
| `stealanegg14.rbxl` | 34,944,300 | `9a6ff179f37388b6e03abca421c8f3343431991f5516cc0d8f2eaf6edac8abd3` |
| `stealanegg14_EN_FR.rbxl` | 34,962,917 | `ce8d0606b357d76a1396c5636aa902e085c05194b31f87674540461fa76ba700` |
| `stealanegg14_EN_FR_COMPLETE.rbxl` | 34,968,802 | `5e25c079a63e154e3f0b8d0e780c7c048d548f82262559910864e40d5c4519c9` |

Their hashes are also stored in `audit/rbxl_checksums.tsv`.

### Remaining transfer limitation

The connected GitHub API can create repository blobs and text files, but it cannot upload the local ~35 MB RBXL binaries or Git LFS objects from this workspace. Therefore these three binary objects are the only essential project artifacts not physically stored in GitHub yet.

The repository is already configured with Git LFS rules for `*.rbxl`. A normal Git/LFS push can complete this final binary step without changing the source layout.
