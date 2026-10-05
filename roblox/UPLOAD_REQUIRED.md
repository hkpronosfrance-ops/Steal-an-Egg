# Binary upload required

The repository is configured for Git LFS.

These files must be added from the local project machine because the ChatGPT GitHub connector used for repository edits cannot stream local binary files directly:

- `roblox/original/stealanegg14.rbxl`
- `roblox/builds/stealanegg14_EN_FR.rbxl`
- `roblox/builds/stealanegg14_EN_FR_COMPLETE.rbxl`

Recommended commands after cloning the repository:

```bash
git lfs install
git lfs track "*.rbxl"

mkdir -p roblox/original roblox/builds

# Copy the three files into the paths above, then:
git add .gitattributes roblox/
git commit -m "backup: add original and localized Roblox places"
git push
```

Keep the original file immutable. New playable snapshots go into `roblox/builds/`.
