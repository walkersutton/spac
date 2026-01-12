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

## 📦 Releasing

1. Tag the commit: `git tag v1.0.0`
2. Push the tag: `git push origin v1.0.0`
3. A draft release with `spac.dmg` and `spac.zip` will be created automatically in the [Releases page](https://github.com/walkersutton/spac/releases).


