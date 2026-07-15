# HyperFrames Setup for Pi Code

## Status

HyperFrames is integrated as native Pi Agent Skills. No React or Remotion adapter is required.

## Installed Locations

- Pi global skills: `${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}/skills/<skill-name>/`
- Entry skill: `${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}/skills/hyperframes/SKILL.md`
- Pinned CLI wrapper: `${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}/bin/hyperframes`
- FFmpeg: `$HOME/.local/bin/ffmpeg` and `$HOME/.local/bin/ffprobe`
- FFmpeg distribution: `$HOME/.local/share/hyperframes/ffmpeg-8.1/`
- HyperFrames render browser: HyperFrames/Puppeteer cache under `$HOME/.cache/`
- RepackMyskill selection: `manifest/hyperframes-selection.json`
- Upstream `init` core-skill copies: `$HOME/.agents/skills/` and `$HOME/.claude/skills/`; some other agent directories may contain symlinks created by upstream installer

## Pinned Sources

- HyperFrames repository: `https://github.com/heygen-com/hyperframes.git`
- Source commit: `ccf5f20b3beea2b245c398a89cb686077b546de2`
- CLI: `hyperframes@0.7.54`
- CLI integrity: exact npm `dist.integrity` SHA-512 from `manifest/hyperframes-selection.json`; installer and wrapper verify it before execution
- CLI Node requirement: Node.js 22+
- License: Apache-2.0

## Verified Environment

- OS: Ubuntu 24.04 x86_64
- Node.js: `v24.18.0`
- npm/npx: `11.16.0`
- FFmpeg/FFprobe: `n8.1.2-22-g94138f6973-20260712`
- Chromium: Snap Chromium 150 available
- HyperFrames Chrome Headless Shell: available through `hyperframes browser path`

## Commands

```bash
# Create blank 1920x1080 project
hyperframes init my-video --non-interactive --example blank --resolution landscape
cd my-video

# Preview in browser
hyperframes preview

# Quality gates
hyperframes lint
hyperframes check

# Environment and browser
hyperframes doctor --json
hyperframes browser ensure
hyperframes browser path

# Render when requested
hyperframes render --output output.mp4
```

Equivalent pinned command when wrapper is unavailable requires manually verifying npm `dist.integrity` against `manifest/hyperframes-selection.json` first:

```bash
npm view hyperframes@0.7.54 dist.integrity
HYPERFRAMES_NO_TELEMETRY=1 HYPERFRAMES_NO_UPDATE_CHECK=1 \
  npx --yes hyperframes@0.7.54 <command>
```

## Pi Invocation

Start a new Pi session or run `/reload`, then use:

```text
/skill:hyperframes
/skill:motion-graphics
/skill:website-to-video
/skill:product-launch-video
/skill:slideshow
```

Example prompt:

```text
Gunakan skill HyperFrames untuk membuat composition HTML-native berdurasi lima detik. Gunakan GSAP timeline yang paused, seekable, deterministic, dan terdaftar sesuai aturan HyperFrames. Jalankan lint dan check sebelum menawarkan render.
```

Pi should load `hyperframes` first, route to a workflow, read `hyperframes-core` before authoring HTML, and use `hyperframes-animation` for motion runtime details.

## Composition Contract

- Root requires `data-composition-id`, `data-width`, `data-height`, and duration/timing metadata.
- Timed elements require `class="clip"`, `data-start`, `data-duration`, and `data-track-index`.
- GSAP timelines must use `{ paused: true }` and be registered in `window.__timelines` by composition ID.
- Animations must be seekable and deterministic. Avoid wall-clock timers, unseeded randomness, and runtime-only side effects.
- Run `lint` and `check` before render.

## Smoke Test Result

Temporary sandbox project (removed after verification)

- Blank official scaffold: PASS
- 1920x1080, 3-second HTML-native composition: PASS
- One tracked title clip: PASS
- Paused, registered GSAP fade-in timeline: PASS
- `hyperframes lint --json`: PASS, 0 errors, 0 warnings
- `hyperframes check --json`: PASS; runtime, layout, contrast, and explicit seekable motion assertions passed across 61 samples
- Preview HTTP startup: PASS
- Preview process and port cleanup: PASS
- Production render: not run by design

## Doctor Result

Render-critical checks passed:

- CLI version: PASS
- Node.js: PASS
- FFmpeg: PASS
- FFprobe: PASS
- Chrome: PASS

`doctor.ok` remains false because these optional capabilities are absent:

- whisper-cpp transcription
- Kokoro local TTS
- MusicGen local BGM
- Docker deterministic container rendering

Local HTML composition lint/check/preview and local MP4 rendering dependencies are ready. Docker-only deterministic rendering is not ready until Docker is installed and running.

## Issues and Resolutions

- Ubuntu 24.04 package candidate was FFmpeg 6.1, below target 7. Installed a checksum-verified FFmpeg 8.1 static build user-locally; no `sudo` and no system binary replacement.
- `npx skills add ... --all --full-depth --yes` installed to project `.agents/skills` and created cross-agent symlinks, not Pi global config. RepackMyskill instead installs the same official skill directories unchanged from a pinned commit into Pi's documented global skill path.
- Official `hyperframes init` refreshed eight core skills in global cross-agent directories even though the smoke project was temporary; current CLI documentation notes `--skip-skills` is temporarily neutered. Those official copies were preserved. Pi's own paths were replaced with native directories to avoid symlink ambiguity.
- Preview parent cleanup left a child CLI process during initial smoke test. The exact preview process was terminated and port closure verified.
- npm emits an existing `python` config deprecation warning. It does not block HyperFrames.
