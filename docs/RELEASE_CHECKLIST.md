# Release checklist

## Ownership / configuration
- [ ] Replace template Admin UserId
- [ ] Replace template GroupId
- [ ] Replace all Game Pass IDs
- [ ] Replace all Developer Product IDs
- [ ] Verify experience/group ownership
- [ ] Verify every external asset permission

## Data / persistence
- [ ] Test first join
- [ ] Test reconnect during session lock window
- [ ] Test server shutdown save
- [ ] Test DataStore failure/retry behavior
- [ ] Test receipt retry/idempotency
- [ ] Test profile migration if schema changes

## Security
- [ ] Rate-limit sensitive remotes
- [ ] Review BagSet trust surface
- [ ] Review SlowMode trust surface
- [ ] Test exploit attempts on Sell/Fuse/Nest/Index/Rebirth
- [ ] Test teleport abuse during egg carry
- [ ] Test duplicated remote payloads

## Gameplay
- [ ] Verify all 12 zones
- [ ] Verify egg spawns/bosses
- [ ] Verify nest placement/hatching
- [ ] Verify pet placement/capacity
- [ ] Fix pet-overlap proximity issue
- [ ] Verify fusion
- [ ] Verify selling
- [ ] Verify trails
- [ ] Verify rebirths
- [ ] Verify Capture the Egg
- [ ] Verify day/night

## Localization
- [ ] French locale pass
- [ ] English locale pass
- [ ] Check image-baked text
- [ ] Check text clipping in French
- [ ] Check dynamic messages

## Performance
- [ ] Test 1 player
- [ ] Test multi-player server
- [ ] Check server memory
- [ ] Check client memory
- [ ] Check network traffic
- [ ] Check Heartbeat/RenderStepped cost
- [ ] Check streaming behavior
- [ ] Check boss AI/pathing cost
