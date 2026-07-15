# RepackMyskill

## Project Purpose

Reproducible public installer for pinned Pi Coding Agent workflow configuration. Never bundle credentials, account config, runtime state, session data, cache, or private user files.

## Project State

ESTABLISHED. Lifecycle installer, sandbox tests, CI static checks, and public release exist on `main`.

## Technology

- Bash with `set -Eeuo pipefail`
- Python 3 for JSON, path, checksum, marker, and state operations
- Git, Node.js 22+, npm/npx, Pi Coding Agent CLI
- GitHub Actions Ubuntu static CI

## Entry Points

| Path | Purpose |
|---|---|
| `install.sh` | Pinned transactional installation and atomic state creation |
| `doctor.sh` | Read-only installation health check; supports `--json` |
| `update.sh` | Reapply repository pins, then run doctor |
| `uninstall.sh` | Conservative managed-file removal and official `pi remove` support |
| `rollback.sh` | Restore validated backup while preserving user-modified files |
| `tests/run-all.sh` | Full sandbox lifecycle suite |
| `HYPERFRAMES_SETUP.md` | HyperFrames versions, locations, commands, and smoke-test status |

## Repository Structure

| Path | Ownership |
|---|---|
| `payload/` | Verified custom files, managed AGENTS fragment, Todo Tools artifacts |
| `manifest/` | Source locks, selection, custom hashes, payload hash manifest |
| `scripts/lib/common.sh` | Shared safe path, transaction, backup, state, checksum helpers |
| `tests/` | Static and temporary-HOME lifecycle tests |
| `docs/` | Inventory and operating documentation |
| `HYPERFRAMES_SETUP.md` | HyperFrames Pi integration, commands, versions, smoke-test evidence |
| `.github/workflows/ci.yml` | Node 22 static CI; no full network install |

## Global Contracts

- Target derives from `${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}`. Never hardcode active source home.
- All scripts use Bash strict mode, reject unsafe paths/symlinks where managed, and do not use `eval`.
- Validate `manifest/payload.sha256` before target mutation.
- State writes are atomic at `$PI_HOME/.repackmyskill/state.json`; state contains no secret.
- Managed `AGENTS.md` content exists only between one `REPACKMYSKILL` marker pair. Preserve non-marker user content.
- Pin package and Git sources from manifests; do not update to arbitrary latest versions.
- HyperFrames installs exactly 20 native skills from `manifest/hyperframes-selection.json`; source commit is pinned and CLI wrapper remains `0.7.54`.
- HyperFrames managed state records only files present in pinned source trees. Preserve destination-only user files; remove stale previously managed files only when their recorded checksum still matches.
- HyperFrames requires Node.js 22+, FFmpeg 7+, FFprobe, and a browser available through `hyperframes browser path`; installer and wrapper verify pinned npm CLI SHA-512 integrity before invoking it.
- Author HyperFrames as HTML-native compositions. Load `hyperframes` first, then `hyperframes-core`; run `lint` and `check` before render.
- Full integration tests must use temporary `HOME` and `PI_CODING_AGENT_DIR`, never active Pi home.
- Active Pi protection checks checksums of all static files. It excludes only `sessions/**`, `logs/**`, `cache/**`, and `tmp/**`.
- Rollback must preflight every entry and fail before mutation when a target has a symlink parent or resolves outside `PI_HOME`.
- `extensions/fable-agent-compat/index.ts` removes forced `isolation` only for Fable Luna, Sol, and Terra Agent calls; all other Agent types remain unchanged.
- Do not track `.pi/`, `node_modules/`, vendor checkouts, backups, sessions, logs, cache, tmp, credentials, or generated artifacts.
- Do not run `npm audit fix --force`, force push, `git reset --hard`, or `git clean`.

## Common Commands

```bash
bash install.sh --dry-run --yes
bash install.sh --yes
bash doctor.sh
bash doctor.sh --json
bash update.sh --yes
bash rollback.sh --backup <backup-path> --yes
bash uninstall.sh --yes
bash tests/test-static.sh
bash tests/run-all.sh
hyperframes doctor --json
hyperframes init my-video --non-interactive --example blank --resolution landscape
hyperframes lint
hyperframes check
```

## Verification

Minimum release gates:

```bash
bash tests/run-all.sh
bash tests/test-static.sh
sha256sum --check manifest/payload.sha256
for file in manifest/*.json; do python3 -m json.tool "$file" >/dev/null; done
git diff --check
```

Run ShellCheck when available. Re-scan staged files for secret patterns and excluded paths before commit.

## Known Constraints

- Full sandbox install requires network, npm, GitHub source access, Pi CLI, FFmpeg 7+, and a HyperFrames-compatible browser.
- CI runs static validation and installer dry-run with an isolated Pi stub; it intentionally skips full third-party network install.
- ShellCheck was not installed in local Phase 3 environment; static CI installs it.
- Todo Tools upstream installation may report its own upstream audit warnings before RepackMyskill replaces lockfile and verifies `npm audit --omit=dev --audit-level=high`.

## Child DOX Index

None. Root contract covers current repository boundaries.
