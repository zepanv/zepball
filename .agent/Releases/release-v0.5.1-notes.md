## Zep Ball v0.5.1

A focused maintenance release that improves editor reliability and fixes shutdown cleanup behavior.

## v0.5.1 Highlights
- Fixed persistent shutdown warnings by adding graceful audio teardown during app quit.
- Fixed level editor save-path consistency for builtin pack editing after test round-trips.
- Added debug-only builtin pack editing controls (`EDIT [DEV]`) for official packs.
- Updated the built-in `advanced-elements` pack with revised level layouts from editor changes.

## Release Assets
- `zepball.zip` (Windows x86_64)
- `zepball.x86_64.zip` (Linux x86_64)
- `SHA256SUMS.txt`
- `SHA256SUMS.txt.minisig`
- `minisign.pub`

## Verify Downloads
```bash
minisign -Vm SHA256SUMS.txt -p minisign.pub
sha256sum -c SHA256SUMS.txt
```
