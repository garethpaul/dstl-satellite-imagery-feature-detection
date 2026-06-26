# Cached download size boundary design

status: approved

## Problem

`download_url` enforces `max_download_bytes` for declared and streamed response
bytes, but a valid ZIP already present in the descriptor-held cache is reused
without checking its compressed file size. A caller lowering the resource limit
therefore receives a cached archive that the same call would reject from the
network.

## Options considered

1. Check `os.path.getsize(filepath)`. This is concise but reintroduces a
   pathname race after the cache file has already been opened safely.
2. Pass the limit into `open_cached_download`. This keeps the check descriptor
   based but mixes opening/type validation with caller policy.
3. Check `os.fstat(handle.fileno()).st_size` inside the existing cached-file
   context before ZIP validation. This uses the already verified descriptor,
   closes cleanly on failure, and keeps the limit beside the cache reuse path.

## Decision

Use option 3. Reject cached archives larger than `max_download_bytes` before
credential loading or network dispatch. Preserve the cached file unchanged and
accept an archive whose size is exactly the configured limit.

## Verification

- Add an offline regression for an oversized valid cached ZIP with missing
  credentials and an injectable session that must remain unused.
- Add static and hostile-mutation contracts for the descriptor-based check.
- Run the pinned multi-runtime verification gate and hosted CI.
