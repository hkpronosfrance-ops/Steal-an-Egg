# Raw archive

This repository keeps both maintainable project sources and selected raw extraction artifacts.

## Preserved

- 89 normalized Luau source files under `src/`
- original/static audit metadata
- complete property metadata
- RBXL parser and inspection tools
- EN/FR localization catalog
- localization patch/rebuild tools
- raw RBX inspection summaries
- raw extraction batch data where practical
- exact size/SHA-256 inventory of local extraction artifacts

The very large `rbxinspect/tree.txt` dump is stored losslessly as ordered parts under:

`audit/raw/rbxinspect/tree_parts/`

Use `audit/raw/rbxinspect/tree.parts.json` for order, source size and SHA-256. Concatenate the parts with no separator to reconstruct the original file.

## Reproducible temporary data

Some `srcchunk_*.json` files were temporary transport containers used while extracting Luau source. They do not contain unique game data: the extracted scripts are already preserved individually in `src/`. Their original filenames, sizes and SHA-256 hashes are retained in `audit/container_inventory.tsv`.

## Binary limitations

The current GitHub connector cannot stream local binary/LFS objects. The RBXL snapshots and other large binary extraction intermediates are therefore identified by cryptographic hashes until they are pushed with a normal Git/Git LFS client.
