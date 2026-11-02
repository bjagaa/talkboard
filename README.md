# TalkBoard for iPad — setup guide

> Also included: `web/index.html`, a browser version that runs from any web server (open in Safari → Share → Add to Home Screen).

A native iPad AAC board for students who use the VersaEye (Hiru) eye tracker.
Works fully offline. Boards are saved on each iPad.

## What you need

- A Mac with **Xcode** (free from the Mac App Store)
- An **Apple ID**
  - Free Apple ID: the app works for **7 days**, then you plug in and reinstall.
  - Apple Developer Program (about $99/year): the app works for a year.
- A **USB-C cable** to connect the iPad to the Mac
- iPad running **iPadOS 17 or later**

## 1. Create the Xcode project (about 5 minutes)

1. Open Xcode → **File → New → Project**.
2. Choose **iOS → App** → Next.
3. Fill in:
   - Product Name: `TalkBoard`
   - Team: your Apple ID (if it's missing, add it in **Xcode → Settings → Accounts**)
   - Organization Identifier: e.g. `org.rtec`
   - Interface: **SwiftUI**, Language: **Swift**, Storage: **None**, no tests needed
4. Save it anywhere.
5. In the left sidebar, **delete** the two files Xcode made: `ContentView.swift` and `TalkBoardApp.swift`
   (choose **Move to Trash**).
6. Drag all seven `.swift` files from this folder's `TalkBoard/` folder into the sidebar,
   under the yellow `TalkBoard` folder. In the dialog, check **Copy items if needed** and the **TalkBoard** target.

## 2. Project settings

Click the blue **TalkBoard** project at the top of the sidebar → select the **TalkBoard** target:

- **General → Supported Destinations**: keep **iPad**. Remove Mac and Vision if listed (iPhone is optional).
- **General → Minimum Deployments**: **iOS 17.0**
- **General → Deployment Info → iPad Orientation**: Landscape Left and Landscape Right
  (keeps the board from rotating if the mount moves)
- **Signing & Capabilities**: check **Automatically manage signing**, choose your Team.
  If it says the bundle ID is taken, change it to something unique, like `org.rtec.talkboard`.

## 3. Install on the iPad over USB-C

1. Plug the iPad into the Mac. On the iPad, tap **Trust** and enter the passcode.
2. Turn on **Developer Mode** on the iPad:
   **Settings → Privacy & Security → Developer Mode → On**. The iPad restarts.
   (The option appears only after the iPad has been connected to Xcode once.)
3. In Xcode's top bar, choose the iPad as the run destination.
4. Press **▶ Run** (⌘R). Xcode builds and installs the app.
5. With a free Apple ID, the first launch is blocked. On the iPad go to
   **Settings → General → VPN & Device Management**, tap your Apple ID, and tap **Trust**.

To install on more iPads, repeat step 3 with each iPad plugged in.

## 4. Set up eye gaze for the student

1. Calibrate the student in the **Hiru** app.
2. **Settings → Accessibility → Touch → AssistiveTouch**: On, with **Dwell Control** On.
3. **Settings → Accessibility → Touch → AssistiveTouch → Devices → Hiru**: turn on **Snap to Item**.
4. In TalkBoard, tap **Adults** (gear icon) three times → keep **Dwell inside the app** Off.
   Turn it on only if you turn AssistiveTouch Dwell Control off, so buttons are never chosen twice.

## 5. Lock the student into the app (Guided Access)

1. **Settings → Accessibility → Guided Access** → On, set a passcode.
2. Open TalkBoard, triple-click the top button, tap **Start**.
3. To exit, triple-click the top button and enter the passcode.

This stops a stray gaze from sending the student to the Home Screen.

## 6. Better voices

On the iPad: **Settings → Accessibility → Spoken Content → Voices → English**,
download an **Enhanced** or **Premium** voice. Then pick it in TalkBoard's settings under **Voice**.

## Using TalkBoard

- Choose words to build a sentence, then **Speak**. Buttons like *yes*, *help*, and *I need the bathroom*
  speak right away.
- **Adults** (tap 3 times): button size, dwell, voice, and **Edit buttons and pages**.
- In edit mode: tap any button to change its emoji, word, spoken text, color type, or page.
  Use **＋ Add button**, **Edit page**, and **New page**. Tap **Done** when finished.

## School-managed iPads

If DCPS manages the iPads with MDM, a self-installed app may be blocked or removed.
The district-approved route is to publish TalkBoard as a **Custom App through Apple School Manager**,
which needs the Apple Developer Program and district IT approval.

## Files

| File | What it does |
|---|---|
| `TalkBoardApp.swift` | App entry point |
| `ContentView.swift` | Sentence strip, page tabs, word grid, adult lock |
| `DwellButton.swift` | Button with optional in-app dwell |
| `Editors.swift` | Settings, button editor, page editor |
| `BoardStore.swift` | Saves boards and settings on the iPad |
| `Speaker.swift` | Text-to-speech (works with the mute switch on) |
| `Models.swift` | Word types, Fitzgerald colors, starter vocabulary |
