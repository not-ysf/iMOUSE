# iMouse iOS

Native iOS app that turns your iPhone into a wireless gyroscope mouse.

Built with SwiftUI + CoreMotion. Install via TrollStore (no Apple Developer account needed).

---

## How to get the IPA (Windows / no Mac)

### Step 1 — Fork this repo on GitHub
Click **Fork** in the top right. You need a free GitHub account.

### Step 2 — Let GitHub build it for you
1. Go to your fork on GitHub
2. Click **Actions** tab
3. Click **Build iMouse IPA** → **Run workflow** → **Run workflow**
4. Wait ~3-5 minutes for the build to finish
5. Click the finished run → scroll down to **Artifacts** → download **iMouse-IPA**

### Step 3 — Install with TrollStore
1. Extract the `.zip` — inside is `iMouse.ipa`
2. Transfer the IPA to your iPhone (AirDrop, Files app, or use [TrollStore's URL install](https://github.com/opa334/TrollStore))
3. Open TrollStore → tap **+** → select `iMouse.ipa` → Install
4. Done! iMouse appears on your home screen.

---

## Using the app

1. Make sure your iPhone and laptop are on the **same WiFi**
2. Run `python server.py` on your laptop (see [server README](../README.md))
3. Open iMouse on your iPhone
4. Enter your laptop's IP address (shown in the server terminal)
5. Tap **Connect**
6. Tilt the phone to move the cursor!

### Controls
| Action | What it does |
|---|---|
| Tilt forward/back | Move cursor up/down |
| Tilt left/right | Move cursor left/right |
| Tap left side | Left click |
| Tap right side | Right click |
| **Recalibrate** button | Reset tilt center point |

---

## Requirements

- iPhone 6s or newer (needs gyroscope)
- iOS 14+
- TrollStore installed (rootless jailbreak)
- Laptop running `server.py` on the same WiFi

---

## Project Structure

```
iMouse-iOS/
├── .github/
│   └── workflows/
│       └── build.yml          ← GitHub Actions build
├── iMouse.xcodeproj/
│   └── project.pbxproj
└── iMouse/
    ├── Sources/iMouse/
    │   ├── iMouseApp.swift    ← App entry point
    │   ├── ContentView.swift  ← UI (setup + mouse view)
    │   ├── WebSocketManager.swift
    │   └── MotionManager.swift ← CoreMotion gyroscope
    └── Resources/
        └── Info.plist
```

---

## Open Source

MIT License. Fork it, improve it, PR welcome!

Ideas for contributions:
- [ ] Scroll wheel (two-finger gesture)
- [ ] Double-click
- [ ] Sensitivity slider in app
- [ ] Dark/light theme
- [ ] iPad support
- [ ] Landscape mode for gaming
