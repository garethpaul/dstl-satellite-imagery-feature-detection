# DSTL Kaggle Explicit Port Design

## Status: Accepted

## Problem

`download_url()` posts Kaggle credentials after validating HTTPS and an exact
Kaggle hostname, but `require_https_url()` currently permits an arbitrary
explicit TCP port. A URL such as `https://www.kaggle.com:444/...` therefore
reaches credential loading and would post credentials to a service selected by
that port rather than Kaggle's default HTTPS endpoint.

## Constraints

- Reject unsafe URL authority before loading credentials or opening a session.
- Preserve the existing exact Kaggle hostname allowlist and HTTPS requirement.
- Keep the default `https://www.kaggle.com/...` download behavior unchanged.
- Keep tests offline and assert that rejected URLs make no session calls.

## Options Considered

1. **Reject every explicit port.** Recommended because the checked-in endpoint
   does not require one and the URL authority remains unambiguous.
2. Allow explicit port 443. Rejected because it adds no required capability and
   weakens the simple default-endpoint policy.
3. Add an allowed-port set. Rejected because no alternate Kaggle port is needed
   and a configurable credential destination would enlarge the security surface.

## Decision

Reject any URL whose parsed authority contains an explicit port. Add offline
regressions for both explicit `:443` and an arbitrary `:444`, require the check
from the static baseline, and synchronize repository security guidance.

## Validation

- Observe the focused test reach credential loading before the source fix.
- Confirm both explicit-port cases fail before credentials or network calls.
- Run unit tests, formatting, lint, compilation, dependency audit, hostile
  mutation checks, and hosted Python matrix verification.
