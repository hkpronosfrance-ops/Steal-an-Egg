# DataStores

Main profile store:

`StealAnEggProfile_v1`

Persisted profile includes coins, speed, Robux spent, playtime, rebirths, settings, eggs, nest eggs, nest animals, pet inventory/index, claims, speed multiplier, equipped bat, trails, plot/mill levels, bag state, gifted passes and purchase receipts.

Other stores include:

- bans: `StealAnEggBans_v1`
- leaderboard prefix: `StealAnEggBoard_`
- global boosts: `StealAnEggBoost_v1`

Current profile implementation uses `UpdateAsync`, ~90s session TTL and ~60s autosave.
