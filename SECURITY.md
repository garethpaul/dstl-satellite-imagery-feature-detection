# Security Policy

## Supported Versions

The supported security scope for `dstl-satellite-imagery-feature-detection` is the current default branch, `master`. Older commits, tags, branches, forks, demos, and generated artifacts are not actively supported unless the repository explicitly marks them as maintained.

Project summary: dstl-satellite-imagery-feature-detection https://www.kaggle.com/c/dstl-satellite-imagery-feature-detection

## Reporting a Vulnerability

Please report suspected vulnerabilities through GitHub's private vulnerability reporting or by opening a draft GitHub Security Advisory for `garethpaul/dstl-satellite-imagery-feature-detection` when that option is available. If GitHub does not show a private reporting option for this repository, contact the repository owner through GitHub and avoid posting exploit details publicly until the issue can be assessed.

Do not open a public issue that includes exploit code, secrets, personal data, or detailed reproduction steps for an unpatched vulnerability.

## What to Include

Helpful reports include:

- the affected file, endpoint, permission, dependency, or workflow
- a concise impact statement explaining what an attacker could do
- reproduction steps using test data and accounts you control
- the branch, commit SHA, platform version, device, runtime, or dependency versions used
- logs, screenshots, or proof-of-concept snippets that demonstrate impact without exposing private data

## Project Security Posture

- This repository appears to be a public sample, documentation, or utility project. The active security scope is the code and documentation on the default branch.
- Review found authentication, token, or session-related code paths; changes in those areas should receive security-focused review before merge.
- Review found network clients, sockets, web APIs, or service endpoints; changes in those areas should receive security-focused review before merge.
- Review found file, document, data, or media parsing flows; changes in those areas should receive security-focused review before merge.
- Review found database, model, query, or persistence-related code; changes in those areas should receive security-focused review before merge.
- Review found secret-like configuration names that require careful review before use; changes in those areas should receive security-focused review before merge.
- No primary dependency manifest was detected in the repository root. If dependencies are added later, include a manifest and prefer reproducible installation instructions.

## Service and API Notes

For web services, APIs, sockets, or scraping workflows, prioritize reports involving authentication bypass, authorization errors, injection, server-side request forgery, unsafe deserialization, credential leakage, data exposure, or denial-of-service conditions. Use test accounts and minimal proof-of-concept traffic only.

Live DSTL downloads must stay restricted to HTTPS Kaggle hosts and filenames in
the checked-in DSTL archive filename list before Kaggle credentials are loaded
or posted. Download URLs with explicit ports or embedded URL credentials are
rejected before local Kaggle credentials are loaded. Download requests must use
a positive finite timeout value or `(connect, read)` pair before requests are posted.
Supplied Kaggle credentials are normalized and rejected when blank before requests
are posted. Zip extraction preflights every member before writing files and
rejects path traversal, archive symlink members and special-file members,
existing symlinks, and colliding destination paths, including portable case and
Unicode normalization collisions, file and directory prefix collisions, plus
existing destination type collisions.
The descriptor-relative no-follow extraction then
holds verified parent directories open, syncs staged files, and atomically
publishes members; unsupported platforms fail closed. GitHub Actions runs the full verification gate on Python
3.10, 3.12, and 3.14 with read-only repository permissions and a bounded
runtime. Cached downloads must be regular non-symlink files, and new partial
downloads are created exclusively to reject concurrent path replacement.
Download roots must remain descriptor-identical from pre-request validation
through archive publication; symlinked or replaced roots fail closed.
Download publication must fail when the final name races into existence;
validated partial files must never overwrite competing destination bytes.
Per-attempt secret-suffixed partial names isolate concurrent downloads so one
request cannot publish or remove another request's in-flight file.
Legacy or collided partial names not created by the current invocation must not
be deleted. Declared response lengths must exactly match streamed bytes.
If cleanup fails after publication, the downloader must remove the final name
owned by that invocation before propagating the failure.
The download root must be revalidated after final publication so a path
replacement present at that validation is detected and the owned final name is
rolled back before an invalid pathname is returned.
Response finalization failures must roll back an invocation-owned published download,
and root identity must be checked again after a successful response close.
Rollback cleanup must verify file identity before unlinking so a raced
replacement is preserved, close failures must not replace an earlier error, and
the published inode must be revalidated after successful response cleanup.
Symlinked extraction roots must be rejected before descriptor traversal.
Cached and newly streamed payloads must also be non-empty ZIP archives before
they are reused or atomically promoted.
Credentialed download, extraction, private dataset, and loader claims require
the exact-head dataset verification matrix. Evidence must use sanitized counts
and size buckets and must not retain credentials, signed URLs, imagery, labels,
private paths, or logs.

## Dependency and Supply Chain Security

Dependency updates should come from trusted package managers and should keep lockfiles in sync when lockfiles exist. Do not commit credentials, private keys, tokens, generated secrets, or machine-local configuration. If a vulnerability depends on a compromised package, typosquatting risk, insecure transitive dependency, or unsafe build step, include the package name, affected version, and the path through which it is used.

## Safe Research Guidelines

Good-faith research is welcome when it stays within these boundaries:

- use only accounts, devices, data, and infrastructure that you own or have explicit permission to test
- avoid destructive actions, persistence, spam, phishing, social engineering, or denial-of-service testing
- minimize access to personal data and stop testing immediately if private data is exposed
- do not exfiltrate secrets or third-party data; report the minimum evidence needed to verify impact
- keep vulnerability details confidential until the maintainer has assessed the report

## Maintainer Response

The maintainer will review complete reports as availability allows, prioritize issues by exploitability and impact, and coordinate a fix or mitigation when the affected code is still maintained. For sample, archived, or educational repositories, the likely remediation may be documentation, dependency updates, or clearly marking unsupported code rather than a production-style patch release.
