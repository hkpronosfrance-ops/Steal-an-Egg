# Zones

The current game uses 12 progression zones:

1. Forest
2. Lake
3. Desert
4. Jungle
5. Snow
6. Volcano
7. Abyss Ocean
8. Prehistoric
9. Cosmic
10. Cherry Blossom
11. Titan Temple
12. Monster Lair

Zone loading is data-driven through `ZoneLoader`, `EggConfig`, attributes and zone assets.

A numbered zone sequence must remain contiguous. A missing zone number can cause later numbered zones to be ignored by the loader.

Streaming keeps a moving window around each player, with early zones treated specially.
