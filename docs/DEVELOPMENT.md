# Developing Heka

Building, testing and contributing. Back to the [README](../README.md).

## Build from source

```sh
git clone git@github.com:lebojo/Heka.git
cd Heka
open Heka.xcodeproj
```

Select the **Heka / My Mac** scheme, then **Run** (⌘R).

Xcode resolves the Swift Package Manager dependencies on first launch:

| Dependency | Version |
| --- | --- |
| [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm) | 1.20.0 (pinned) |
| [Textual](https://github.com/gonzalezreal/textual) | 0.5.0 (pinned) |

SwiftTerm stays on 1.20.0, the last 1.x release, until Heka migrates to its 2.0 API. A plain bump to 1.99.x breaks Heka in three ways:

- `TerminalView.getTerminal()` no longer exists, and Heka reads the emulator through it in 13 places.
- `LocalProcessTerminalView` no longer calls `dataReceived(slice:)`, which Heka overrides to feed the phone mirror, `heka terminal wait --idle` and agent activity. With 1.99.0 and 1.99.1 these go silent without any build error; from 1.99.2 the override no longer compiles.
- `processTerminated` now passes the exit code itself rather than the raw wait status, so `TerminalSessions` would decode it twice and read an exit code of 1 as signal 1.

The migration (upstream `MigratingFrom1To2`) runs Heka's own `LocalProcess` with a `LocalProcessDelegate` feeding a plain `TerminalView`, so the output bytes stay available. Bump the pin only together with that change.

Xcode may ask you to enable the `SwiftTermBuildInfoPlugin` plugin, which generates SwiftTerm's version information.

Command-line build:

```sh
xcodebuild -project Heka.xcodeproj -scheme Heka -configuration Debug \
  -derivedDataPath /tmp/heka-build -skipPackagePluginValidation build CODE_SIGNING_ALLOWED=NO
```

The repository includes a shared **Heka-iOS** scheme and Xcode Cloud build scripts for iOS beta distribution. The **iOS Beta** workflow builds and archives release tags for TestFlight. Its settings and first-run checks are documented in [ci_scripts/README.md](../ci_scripts/README.md).


## Project structure

```
Heka/
├── Heka/
│   ├── MyApp.swift
│   ├── Core/         # Remote channel, security, chat journals and terminal mirror
│   ├── Models/       # Workspace, stores, bridge protocol, inspector models
│   ├── Services/     # Git, heka CLI, bridge, command execution, persistence
│   ├── Platforms/    # macOS and iOS adapters
│   ├── Views/        # One folder per screen (ContentView, WorkspaceSidebar, TerminalDetail, …), one view per file
│   │   └── Components/  # Views shared between screens
│   └── Heka.icon  # Icon Composer icon
├── Tests/            # Unit tests (run.sh) and integration tests (integration.py)
└── Heka.xcodeproj
```

## Tests

```sh
# Unit tests (compiled with swiftc, no Xcode needed)
./Tests/run.sh

# Integration tests against a Debug app built in /tmp/heka-build
python3 Tests/integration.py

# Companion integration (isolated Mac host, real TCP + PTY; needs Python 3.13+ for TLS-PSK)
python3 Tests/remote-integration.py /tmp/heka-mobile-build/Build/Products/Debug/Heka.app/Contents/MacOS/Heka

# Terminal checkpoints + UIKit regression app in a disposable simulator.
# First build macOS and iOS Simulator Debug into these derived-data directories.
bash Tests/run-terminal-mirror.sh /tmp/heka-mobile-build /tmp/heka-ios-build
```

Integration tests launch a Debug instance with temporary state and repositories, never the user's data. Companion integration tests use a dynamically allocated loopback port and verify the fixture path before sending input, so an already-running Mac host is never used. With `Tests/remote-integration.py --hold` (app path before `--hold`), launch a disposable iPhone simulator with `SIMCTL_CHILD_HEKA_TEST_HOST_PORT` set to the printed port, and pass `-remoteHost 127.0.0.1 -remotePairingCode <printed code>` as launch arguments. `HEKA_SIM=<UDID> SERVE_SIM_ROOT=<serve-sim/dist> node Tests/mobile-navigation.cjs` checks project/worktree expansion, terminal navigation and back navigation through real UI taps. They check the real PTY, delegation from a terminal, paths, Git and persistence. Regression tests also cover write failures, save ordering, Observation isolation, stopping a stuck Git hook, partial worktree recovery and local reads during a slow GitHub request.

If the macOS session cannot focus the test window, `HEKA_SKIP_WINDOW_TESTS=1 python3 Tests/integration.py` runs the other scenarios and explicitly reports the skipped keyboard/window tests. Automated captures do not validate the native appearance under Stage Manager; visual inspection still has to be done in a normal window.

## Continuous integration

Every pull request and every push to `main` triggers the [CI](../.github/workflows/ci.yml) workflow on GitHub `xcode-27` runners. The **Build** job lints the views, runs the unit tests, builds the macOS and iOS Simulator Debug apps and runs the terminal mirror tests; the **Release build** job compiles the universal (arm64 and x86_64) macOS Release configuration in parallel. The `main` branch is protected: changes go through a pull request whose **Build** check must pass.

## Contributing

1. Create a branch from `main`.
2. Check the build and `./Tests/run.sh` locally.
3. Open a pull request; it can be merged once CI is green and conversations are resolved.

