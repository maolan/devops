# Agent Instructions: Maolan

This file describes the Maolan project for AI coding agents. Read it before
making changes anywhere in this repository tree.

## Project overview

Maolan is an open-source Digital Audio Workstation (DAW) written in Rust,
focused on recording, editing, routing, automation, export, and plugin hosting.
The repository root is a multi-crate project directory, not a single Cargo
workspace. Each major component lives in its own subdirectory with its own
`Cargo.toml`, `.git` history, and (where applicable) its own `AGENTS.md`.

The main application is in `maolan/`. The audio engine is in `engine/`. Custom
CLAP plugins are in `plugins/`. Reusable iced widgets are in `widgets/`.
Out-of-process plugin hosting is implemented in `maolan/plugin-host/` and
`plugin-protocol/`. AI audio generation tooling lives in `generate/`, and the
project website is in `site/`.

## Repository layout

```
.
├── baseview/           # Low-level windowing system for plugin UIs
│                         (fork, licensed MIT OR Apache-2.0)
├── maolan/                # Main Maolan DAW application (Cargo workspace)
│   ├── Cargo.toml      # Workspace: members [".", "plugin-host"]
│   ├── plugin-host/    # Out-of-process plugin host binary + library
│   ├── src/            # Main GUI application, CLI binaries, state, workspace UI
│   ├── bin/            # Additional binaries: maolan-cli, maolan-osc, maolan-test
│   ├── docs/           # User documentation (FEATURES, OPERATIONS, SHORTCUTS, ...)
│   ├── scripts/        # Linux build scripts and Windows PowerShell build script
│   └── desktop/        # .desktop files for Linux/BSD
├── engine/             # maolan-engine audio engine crate
│   └── src/            # Engine, track processing, plugin wrappers, hardware backends
├── esaxx/              # Suffix-array wrapper crate (esaxx-rs)
├── generate/           # maolan-generate / HeartMuLa generation crate
├── github/             # GitHub profile assets
├── mixosc/             # OSC control surface for Behringer X32/X-Air mixers
├── nsis-3.10/          # NSIS installer tooling for Windows builds
├── plugin-protocol/    # Shared IPC protocol for out-of-process plugins
├── plugins/            # maolan-plugins CLAP plugin collection
├── site/               # Hugo website sources
├── trainer/            # NAM-compatible model trainer
└── vocal/              # RVC-style voice conversion scaffold
```

## Technology stack

- **Language:** Rust, edition 2024, stable toolchain.
- **GUI framework:** iced 0.14 with the `advanced`, `image`, `lazy`, and `tokio`
  features; `iced_aw`, `iced_fonts`, and `iced_drop`.
- **Async runtime:** Tokio (full feature set in most crates).
- **Audio backends:**
  - Linux / FreeBSD: ALSA and JACK.
  - macOS: CoreAudio.
  - Windows: WASAPI (via `cpal`).
- **Plugin formats:** CLAP, VST3, LV2 (Unix only). Plugins are hosted
  out-of-process for crash isolation.
- **Plugin UI embedding:** X11 on Unix, HWND `SetParent` on Windows.
- **AI / ML:** Burn 0.21.0 with `ndarray` and `wgpu` backends; `hf-hub` for
  model download; `safetensors` / `burnpack` for model artifacts.
- **Audio processing helpers:** `rubato` (resampling), `rubberband` (time/pitch),
  `ffmpeg-next` (import/export codecs), `wide` (SIMD), `rustfft`, `rayon`.
- **Website:** Hugo static site generator (`site/hugo.toml`).

## Build commands

There is **no root Cargo workspace**. Build commands must be run from the
relevant crate directory.

### Main DAW (`maolan/`)

```bash
cd maolan
cargo build --workspace
cargo run               # runs the default maolan GUI binary
cargo test --workspace --all-targets
```

Release build:

```bash
cd maolan
cargo build --workspace --release
```

The workspace produces the following binaries:

- `maolan` (default GUI application)
- `maolan-cli` (command-line interface)
- `maolan-osc` (small OSC transport helper)
- `maolan-test` (engine/plugin test binary)
- `maolan-plugin-host` (out-of-process plugin host)

### Engine (`engine/`)

```bash
cd engine
cargo build
cargo test --all-targets
```

### Plugins (`plugins/`)

```bash
cd plugins
cargo build --release
```

The crate builds a single `cdylib` (`maolan_plugins.so` / `.dll` / `.dylib`)
containing all Maolan CLAP plugins.

### Other crates

```bash
cd widgets && cargo build && cargo test --all-targets
cd plugin-protocol && cargo build && cargo test --all-targets
cd generate && cargo build && cargo test --all-targets
cd mixosc && cargo run
cd baseview && cargo build && cargo test --all-targets
```

### Platform prerequisites

- **Linux / FreeBSD:** `pkg-config`, JACK/ALSA dev packages, `liblilv-dev`,
  `libsuil-dev`, `libgtk2.0-dev`, `librubberband-dev`, FFmpeg libraries,
  LLVM/Clang (for bindgen).
- **Windows:** Visual Studio Build Tools, LLVM/Clang, NSIS, vcpkg packages
  (`sentencepiece:x64-windows`), FFmpeg NuGet package. See
  `maolan/scripts/build.ps1` and `plugins/build.ps1` for the automated setup.
- **macOS:** Xcode / Command Line Tools, CoreAudio frameworks.

## Code style guidelines

- All Rust code uses **edition 2024**.
- Run `cargo fmt` before finishing any change.
- Run `cargo clippy --all-targets --fix --allow-dirty` and fix remaining
  warnings manually. **Do not use `#![allow(...)]` or `#[allow(...)]` to
  silence clippy warnings.** Address the underlying issue.
- Prefer debug builds for development and testing unless release is explicitly
  requested.
- `baseview/` has its own `.rustfmt.toml` and `clippy.toml`; respect those
  when editing that crate.
- `plugins/src/lib.rs` starts with `#![deny(dead_code)]`. Keep unused code out
  of the plugins crate.

## Testing instructions

- Unit tests are embedded in source files via `#[cfg(test)]` modules. There are
  very few separate integration-test directories.
- Run tests with `cargo test --all-targets` from the relevant crate directory.
- CI workflows run:
  ```bash
  cargo fmt --check
  cargo clippy --all-targets -- -D warnings
  cargo test --all-targets
  ```
- Some tests are platform-gated (for example `maolan/plugin-host/tests/windows_clap_load.rs`
  is `#![cfg(all(test, windows))]`).
- Some plugin tests in `plugins/tests/synth_dsp.rs` exercise the synthesizer
  DSP and assert on signal properties such as finite output, pitch, and filter
  stability.

## Runtime architecture

- The DAW runs as a **main GUI process** that owns project state and the
  timeline UI.
- The audio engine is driven from the main process via an async message
  channel (`maolan_engine::message::Message`).
- **Plugins are never loaded directly into the DAW process.** Each plugin
  instance runs in a separate `maolan-plugin-host` OS process. The DAW and
  host communicate through shared memory (`mmap` / `CreateFileMappingW`) and
  cross-process events (`pipe` / named events). If a host process crashes, the
  DAW detects it, bypasses the plugin, and continues playback.
- Plugin scan paths can be overridden with `CLAP_PATH` and `VST3_PATH`.

## Session and storage conventions

- User preferences: `~/.config/maolan/config.toml`.
- Session templates: `~/.config/maolan/session_templates/<name>/`.
- Track templates: `~/.config/maolan/track_templates/<name>/`.
- A session directory contains `<branch>.json`, `audio/`, `midi/`, `peaks/`,
  `pitch/`, `plugins/`, `.maolan_commits/`, and `.maolan_autosave/snapshots/`.
- Autosave snapshots are written every 15 seconds.

## Security considerations

- Plugin hosting is intentionally **out-of-process** to isolate untrusted
  plugin code. Do not change this to in-process loading without explicit
  discussion.
- The codebase contains substantial `unsafe` code for FFI, shared memory, SIMD,
  and platform audio APIs. Verify unsafe blocks for correctness and minimal
  scope; document invariants in comments.
- Shared-memory layouts in `plugin-protocol` use fixed offsets and atomic
  operations. Changes to these layouts affect both the DAW and plugin-host
  binaries and must be versioned or kept in sync.
- File dialogs and plugin scanning can touch user paths and third-party
  binaries. Validate paths, avoid directory traversal, and do not execute
  plugin code in the DAW process.
- The `maolan-osc` helper sends UDP packets to `127.0.0.1:9000`; the engine
  listens on `0.0.0.0:9000` when OSC is enabled in preferences.

## Per-crate agent instructions

Some subdirectories contain their own `AGENTS.md` with more specific routines:

- `engine/AGENTS.md` — end-of-change clippy + fmt routine, debug-build policy.
- `plugins/AGENTS.md` — currently duplicates the `maolan` routine (clippy + fmt).

When working in a subdirectory, follow its local `AGENTS.md` if present, and
update this root file if you change cross-cutting conventions.

## Deployment

- **Linux CI:** `.github/workflows/rust.yml` in each crate runs formatting,
  clippy, and tests. `maolan/.github/workflows/release.yml` triggers a release
  build that packages `maolan`, `maolan-cli`, `maolan-osc`, and desktop files
  into a `.tar.gz` artifact.
- **Windows:** `maolan/scripts/build.ps1` and `plugins/build.ps1` install
  dependencies, build release binaries, and produce NSIS installers.
- **Linux packaging:** `maolan/scripts/build-ubuntu.sh`, `build-debian.sh`, and
  `build-fedora.sh` build distribution packages.
- **Website:** `site/` is a Hugo site deployed to `https://maolan.github.io/`.

## Notes for agents

- The repository root has no `Cargo.toml`; do not run `cargo build` from the
  root expecting it to work.
- Many crates are published to crates.io independently (for example
  `maolan-engine`, `maolan-widgets`, `maolan-generate`). Version bumps and
  publish steps should be coordinated across crates that depend on each other.
- When editing one crate, check dependent crates in sibling directories for
  breakages. There is no workspace-level `cargo check --workspace` at the root;
  you must check each crate individually.
- Documentation for users is in `maolan/docs/`. Keep it in sync when changing
  user-visible behavior, shortcuts, or file formats.
