# Cached download identity binding design

status: approved

## Problem

`download_url` validates a cached ZIP through a no-follow descriptor, closes the
descriptor, and returns the cache pathname after checking only the output-root
identity. A concurrent replacement of the filename during validation can
therefore make the returned path name a different file from the ZIP that passed
validation.

## Options considered

1. Reopen and revalidate the pathname. This repeats archive work and still
   leaves the same descriptor-to-path transition afterward.
2. Keep only the existing output-root identity check. This protects the parent
   directory but does not bind the validated file identity.
3. Capture the validated descriptor fingerprint and compare it with a no-follow
   pathname stat before cache reuse. This matches the existing downloaded-file
   publication boundary and rejects replacements without deleting unowned data.

## Decision

Use option 3. Capture device, inode, change time, and size after ZIP validation,
then require the cached pathname to remain the same regular file after the root
identity check. Reject a mismatch before logging reuse or returning the path.

## Verification

- Add an offline regression that replaces the cache pathname after descriptor
  validation and proves the replacement remains untouched.
- Add source, test, documentation, and hostile-mutation contracts.
- Run the pinned local verification gate and hosted CI.
