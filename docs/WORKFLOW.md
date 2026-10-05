# Development workflow

## Source of truth

Use GitHub for:
- Luau source
- configuration
- documentation
- localization
- audits and manifests
- release notes

Use Roblox place snapshots for:
- complete world geometry
- instances and properties not represented in Rojo source
- binary backup / disaster recovery

## Recommended flow

1. Work on a branch.
2. Change Luau/config files.
3. Test in Roblox Studio.
4. Export a tested RBXL snapshot when appropriate.
5. Commit source changes with a descriptive message.
6. Tag stable milestones.

## Commit examples

- `feat: add French localization`
- `fix: prevent pet overlap in pens`
- `security: harden BagSet validation`
- `config: replace template monetization IDs`
- `balance: adjust rebirth progression`
