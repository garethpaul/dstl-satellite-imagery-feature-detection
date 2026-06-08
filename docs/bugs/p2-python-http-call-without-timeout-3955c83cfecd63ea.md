# [P2] Set explicit timeouts on outbound HTTP calls

## Severity

P2 - reliability/availability

## Evidence

- `utils.py:50`: `r = requests.post(url, data=kaggle_info, stream=True)`

## Problem

Python HTTP clients default to waiting forever when no timeout is set. If an upstream service accepts the connection and then stalls, request handlers, bot callbacks, or data download scripts can hang indefinitely.

## Suggested fix

Pass a bounded `timeout` to each `requests` or `urlopen` call, choose separate connect/read values where useful, and handle timeout exceptions with a clear retry or error path.

## Review metadata

- Repository: `garethpaul/dstl-satellite-imagery-feature-detection`
- Reviewed commit: `037be65ad764fd2ab3f130fad698b4bf1e3f2d7f`
- Labels: `bug`, `codex-review`, `severity:P2`
- Codex review fingerprint: `3955c83cfecd63ea`
