# DSTL Dataset Integration Verification Matrix

Use this matrix for exact-head evidence that cannot be inferred from offline
checks. Run it only in a private competition-authorized environment with local
credentials and dataset storage outside the repository. Record sanitized
counts and size buckets; never retain Kaggle credentials, signed URLs, account
identifiers, archive contents, imagery, labels, screenshots, paths, or logs.

Commit: pending implementation commit
Pull request: pending
Evidence status: not run

| # | Scenario | Boundary | Required sanitized evidence | Status |
|---|---|---|---|---|
| 1 | Isolated environment setup | Private runtime | Commit, Python version, platform class, and synthetic environment identifier | not run |
| 2 | Missing credential preflight | Credential boundary | Missing-field class, exit status, and request count | not run |
| 3 | Valid credential preflight | Credential boundary | Credential source class, normalization result, and request count before download | not run |
| 4 | Cached archive reuse | Local cache | Archive class, validation result, request count, and size bucket | not run |
| 5 | Bounded Kaggle download | Live Kaggle | Archive name class, response status, elapsed-time bucket, and size bucket | not run |
| 6 | Invalid download payload | Private synthetic endpoint | Payload class, rejection result, and partial-file cleanup result | not run |
| 7 | Archive member preflight | Private dataset | Member-count bucket, expanded-size bucket, and preflight result | not run |
| 8 | Safe archive extraction | Private dataset | Archive class, extraction result, and published-file count bucket | not run |
| 9 | Destination collision rejection | Synthetic archive | Collision class, rejection result, and published-file count | not run |
| 10 | Destination race containment | Synthetic archive | Race class, rejection result, and partial-artifact count | not run |
| 11 | Dataset archive inventory | Private dataset | Expected archive count, present count, and missing-name classes | not run |
| 12 | Extracted dataset inventory | Private dataset | Imagery-count bucket, label-count bucket, and unexpected-type count | not run |
| 13 | Resource budget enforcement | Private runtime | Configured byte/member limits, observed buckets, and enforcement result | not run |
| 14 | Loader smoke behavior | Private dataset | Input class, output shape class, elapsed-time bucket, and peak-memory bucket | not run |

## Evidence Rules

- Replace the pending commit and pull-request fields with the exact tested head
  before recording any scenario as `pass`, `fail`, or `blocked`.
- Use only `pass`, `fail`, `blocked`, or `not run`; explain blockers without
  embedding credentials, private identifiers, dataset names, or machine paths.
- Keep offline checks, synthetic archive tests, credentialed downloads,
  extracted dataset evidence, and loader evidence separate.
- A unit test, source check, compile, lint, or dependency audit cannot mark an
  integration scenario as passed.

No credentialed Kaggle download, competition archive extraction, private
dataset inventory, or dataset loader scenario was executed for this
documentation-only change.
