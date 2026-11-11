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
| [MarkdownUI](https://github.com/gonzalezreal/swift-markdown-ui) | 2.4.1 (pinned) |
| [swift-argument-parser](https://github.com/apple/swift-argument-parser) | 1.8.2 |

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

# Companion integration (isolated Mac host, real TCP + PTY)
python3 Tests/remote-integration.py /tmp/heka-mobile-build/Build/Products/Debug/Heka.app/Contents/MacOS/Heka

# Terminal checkpoints + UIKit regression app in a disposable simulator.
# First build macOS and iOS Simulator Debug into these derived-data directories.
bash Tests/run-terminal-mirror.sh /tmp/heka-mobile-build /tmp/heka-ios-build
```

Integration tests launch a Debug instance with temporary state and repositories, never the user's data. Companion integration tests use a dynamically allocated loopback port and verify the fixture path before sending input, so an already-running Mac host is never used. With `Tests/remote-integration.py --hold` (app path before `--hold`), launch a disposable iPhone simulator with `SIMCTL_CHILD_HEKA_TEST_HOST_PORT` set to the printed port, and pass `-remoteHost 127.0.0.1 -remotePairingCode <printed code>` as launch arguments. `HEKA_SIM=<UDID> SERVE_SIM_ROOT=<serve-sim/dist> node Tests/mobile-navigation.cjs` checks project/worktree expansion, terminal navigation and back navigation through real UI taps. They check the real PTY, delegation from a terminal, paths, Git and persistence. Regression tests also cover write failures, save ordering, Observation isolation, stopping a stuck Git hook, partial worktree recovery and local reads during a slow GitHub request.

If the macOS session cannot focus the test window, `HEKA_SKIP_WINDOW_TESTS=1 python3 Tests/integration.py` runs the other scenarios and explicitly reports the skipped keyboard/window tests. Automated captures do not validate the native appearance under Stage Manager; visual inspection still has to be done in a normal window.

## Continuous integration

Every pull request and every push to `main` triggers the [CI](../.github/workflows/ci.yml) workflow on a GitHub `xcode-27` runner: a Debug build of the app, then the unit tests. The `main` branch is protected: changes go through a pull request whose **Build** check must pass.

## Contributing

1. Create a branch from `main`.
2. Check the build and `./Tests/run.sh` locally.
3. Open a pull request; it can be merged once CI is green and conversations are resolved.

