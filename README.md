# spac

<p align="center">
  <img src="assets/logo.png" width="100" alt="spac logo">
  <br>
  <strong>A minimal macOS Caps Lock HUD.</strong>
  <br>
  <br>
  <img src="https://github.com/user-attachments/assets/bac965f6-5df3-462e-82d3-f38482f85db3" alt="spac demo">
  <br>
  It's kinda like <a href="https://apps.apple.com/us/app/capslocker/id1102304865">CapsLocker</a> but free and designed for macOS Tahoe
</p>

## 🚀 Installation

### Download the DMG

1. Download the latest `spac.dmg` from the [Releases](https://github.com/walkersutton/spac/releases) page.
2. Open the DMG and drag `spac.app` to your Applications folder.
3. **Right-Click** on `spac.app` and select **Open** to bypass the "unidentified developer" warning (Ad-Hoc signed).

## 🛠️ Development

### Building from Source

```sh
xcodebuild -scheme spac \
  -configuration Release \
  -derivedDataPath build
```

### Devving

```sh
make preview
```

## 📦 Releasing

1. Commit or stash any local changes.
2. Run `make release-patch`, `make release-minor`, or `make release-major`.
3. A GitHub release with `spac.dmg`, `spac.zip`, and `appcast.xml` will be created automatically.

Use `scripts/bump-version.sh` with no arguments to keep the public version and increment only the build number. Use `scripts/bump-version.sh --print` to show the current version.

Use `scripts/release.sh 1.2.3` to release a specific version. Release versions use `MAJOR.MINOR.PATCH`; each release automatically increments the build number, commits the version bump, tags the commit, and pushes the branch and tag.
