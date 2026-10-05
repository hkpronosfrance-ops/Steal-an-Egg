# Assets

The project references a large number of Roblox-hosted assets across scripts and instance properties.

The audit currently tracks:
- script-referenced Asset IDs
- meshes/textures/animations/sounds referenced by the place
- asset-manifest/preloader behavior
- external monetization identifiers separately

Important: an `.rbxl` can reference Roblox-hosted assets without embedding the original uploaded source file. A complete disaster-recovery plan therefore includes both:
1. the place snapshots
2. an inventory of every external Roblox Asset ID and its usage

Before release, verify that each asset is usable by the final experience/group and is not dependent on the template seller's ownership permissions.
