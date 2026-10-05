# Security audit

Static source audit found no classic remote-code backdoor patterns:

- no `loadstring`
- no numeric remote `require(assetId)`
- no Pastebin/Discord webhook loader
- no HTTP-downloaded executable code
- no suspicious `InsertService:LoadAsset` loader

Important production items still to change:

- template Admin UserId: `4954213545`
- template GroupId: `462497082`
- all Game Pass and Developer Product IDs
- review client-writable BagState
- review SlowMode client trust
- strengthen session locking margin
- runtime exploit/rate-limit testing

Most economy-sensitive actions are revalidated server-side.
