# Monetization

The purchased template already contains configured Roblox monetization IDs.

Systems include:
- 2x Growth game pass
- 2x Money game pass
- Speed multiplier passes up to x256
- Speed packs
- Cash packs
- Trails
- Skip Growth
- Grow All
- Pen upgrades
- Treadmill upgrades
- Rebirth skip
- Gifts
- Boss-related offers

## Production checklist

Before release:
1. replace every Game Pass ID
2. replace every Developer Product ID
3. verify prices against the live Roblox catalog
4. verify ownership belongs to the intended account/group
5. test ProcessReceipt retry behavior
6. test failed/aborted purchases
7. verify gifted pass handling

Known template identifiers that must be replaced:
- Admin UserId: `4954213545`
- GroupId: `462497082`

Receipt processing is centralized in `PurchaseService` and purchase IDs are persisted to reduce duplicate grants.
