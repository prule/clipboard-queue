# Development environments

Whether Clipboard Queue can be developed in a container or a VM, and what each
option actually buys you. Short version: **devcontainers cannot work at all**,
and a **macOS VM works but earns its keep only for OS-version testing**.

## Devcontainers do not work

Devcontainers are Linux containers. On a Mac they run inside a Linux VM, and
there is no container runtime for macOS userland — so no image can provide
AppKit. Swift itself runs fine on Linux (there are official `swift:6.x` images),
but the Apple UI frameworks are closed-source and macOS-only.

The app is bound to them almost everywhere:

| Framework | Files importing it | Available on Linux |
|---|---|---|
| SwiftUI | 7 | No |
| AppKit | 4 | No |
| `Carbon.HIToolbox` | 2 (`App.swift`, `HotKeys.swift`) | No |
| Foundation only | 1 (`Models.swift`) | Yes, via swift-corelibs-foundation |

`Package.swift` also declares `platforms: [.macOS(.v14)]`, so `swift build`
fails before it reaches the first `import SwiftUI`. Only `Models.swift`
(`ClipList`, `QueueItem`, `Accent`, `Density`, the seed data) is portable, and
splitting one file into its own containerized target buys nothing.

A container could still host an agent that *edits* Swift, runs git and writes
OpenSpec artifacts — but it could not build or launch the app. Since this
project has no test target and verification is build-and-run, that removes the
only thing that catches real behaviour.

Revisit this only if the Windows/Linux port noted in `openspec/config.yaml` ever
happens. A Linux devcontainer would genuinely help build that variant, but the
per-platform abstraction does not exist yet.

## macOS VM (UTM)

### How it would work

UTM has two backends. A macOS guest requires the **Apple Virtualization**
backend — Apple silicon hosts only. UTM installs macOS from an IPSW restore
image into a VM bundle. On an 8-core / 24 GB host, allocate 4 cores and 8 GB to
the guest.

**Run the agent inside the guest, with the repo in the guest.** This is the
decision that determines whether the VM is useful. From the host, an agent
cannot drive the guest's UI — it loses `osascript` key injection and
`screencapture`, which is how queue behaviour gets verified in practice. Inside
the guest it has full native control: `swift build`, `open`, hot-key injection,
screenshots, and free rein over `~/.clipboardqueue/`.

Guest setup is small: Command Line Tools (`xcode-select --install`, ~1.5 GB).
This project deliberately needs no Xcode, so the 15 GB download is skipped. Then
git and the agent tooling. Share the repo over VirtioFS for host-side editing,
or clone it fresh in the guest for real isolation.

**Disable host↔guest clipboard sharing.** This matters specifically for this
app: `AppStore` parks the queue whenever the pasteboard changes in a way it did
not cause. A clipboard bridge injects host copies into the guest pasteboard, and
the app reads them as "the user copied something of their own" and parks
mid-test. An isolated guest pasteboard is the correct environment here — it is a
correctness requirement, not just a safety preference.

### Pros

- **Destructive testing without touching real data.** Verifying the storage-path
  change on the host required checksumming the live `lists.json` and backing up
  `~/.clipboardqueue/` before touching it. In a guest, `rm -rf ~/.clipboardqueue`
  costs nothing.
- **Genuine first-launch state.** The seeding path and the "no file at the new
  location" scenario in `openspec/specs/list-storage-location/spec.md` are only
  honestly testable on a machine that has never run the app.
- **Tests the declared deployment target.** `Package.swift` claims macOS 14+, but
  development happens on macOS 26. A macOS 14 guest turns that claim from an
  assumption into a verified fact. **This is the strongest reason to build one.**
- **Pre-granted TCC permissions.** Screen-recording and Accessibility prompts
  interrupt agent-driven UI verification on the host. In a guest you grant them
  once, or disable SIP outright — reckless on a primary machine, fine on a
  disposable VM.
- **Near-native build speed.** `swift build` takes ~3.5 s on the host; expect
  ~5–7 s in the guest. Irrelevant at this project size.

### Cons

- **Disk.** A macOS guest needs 60–90 GB (base install ~45 GB, plus tooling and
  growth).
- **No snapshots on the Apple VZ backend.** UTM's snapshot feature is tied to its
  QEMU/qcow2 backend; VZ macOS guests do not get it. Rolling back means
  duplicating the whole VM bundle — tens of GB and minutes, versus seconds. This
  blunts the VM's biggest advantage. *Worth confirming against your UTM version
  rather than taking on faith.*
- **No iCloud/Apple ID in the guest** (no hardware identity). Irrelevant to this
  app; limiting if the guest doubles as a general workspace.
- **Working through a VM window.** `⌃⌥←/→` should pass through cleanly — macOS's
  own Spaces shortcuts are `⌃←/→`, without Option — but it is still a layer of
  friction on an app you interact with constantly.
- **Two environments to maintain**: toolchain, dotfiles, git credentials, agent
  config.
- **Host resources split** while the guest runs.

## Recommendation

Not worth it for routine work. The app is a thin SwiftUI shell over a small
state machine, and host-side verification with a checksum and a backup has been
sufficient. The VM's headline benefit — throwaway state — is exactly what the
Apple VZ backend cannot provide cheaply without snapshots.

Build one for a **macOS 14 compatibility pass** before shipping this to anyone
else. That is a real, currently unverified gap.

For fast disposable macOS environments generally, **Tart** fits better than UTM:
same Virtualization.framework underneath, but CLI-driven with APFS
copy-on-write clones, so cloning is near-instant and nearly free on disk — the
snapshot workflow UTM will not give you here. It still needs the disk for the
base image.

## Host measurements

Taken 2026-08-06 on the development machine; re-check before acting on them.

| | |
|---|---|
| Architecture | arm64 (Apple silicon) |
| macOS | 26.5.2 (build 25F84) |
| CPU / RAM | 8 cores / 24 GB |
| Free disk | **13 GB of 460 GB (97% full)** |
| UTM | 4.7.5 |

The free-disk figure is the blocker: roughly **70 GB would need to be freed**
before a macOS guest could be installed at all.
