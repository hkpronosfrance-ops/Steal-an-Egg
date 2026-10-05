# Architecture

The purchased place contains 89 Luau sources:

- 29 server Scripts
- 34 LocalScripts
- 26 ModuleScripts

Main systems:

- `StatsService` — persistence/session profile
- `EggBossService` — world eggs, carrying, bosses, banking
- `NestService` — egg placement, growth, hatch, animals, passive income
- `PlotService` / `PlotUpgradeService` — player plots and upgrades
- `PetIndexService` — collection/index rewards
- `FuseService` — three-pet fusion
- `SellService` — selling pets/eggs
- `RebirthService` — rebirth progression
- `TrailService` — trails and multipliers
- `PurchaseService` / `ShopService` / `SpeedShopService` — monetization
- `GlobalBoostService` — cross-server boosts
- `CaptureEggService` — synchronized event lifecycle
- `DayNightService` — day/night gameplay modifier
- `ZoneLoader` / `ZoneStreaming` — data-driven zones and streaming

The project currently uses several service handles exposed through `_G`. Future refactors should avoid increasing this dependency.
