# Aaron's Deluge — Personal Firmware Notes

This is a personal fork of the [Deluge Community Firmware](https://github.com/SynthstromAudible/DelugeFirmware).
Built for sample-collage / loop-layering / songwriter workflows.
Not for EDM. Not for CV. Not for MIDI routing nerd stuff.

---

## What's different from stock firmware

### Button remaps

| Button | Stock behavior | Aaron's behavior | To get original |
|--------|---------------|-----------------|-----------------|
| **MIDI** | Opens MIDI instrument menu | Opens **sample browser** (STRETCH mode) | Hold **Shift + MIDI** |
| **CV** | Opens CV instrument menu | **Creates audio clip** instantly, ready to monitor line in | Hold **Shift + CV** |
| **LEARN/INPUT** | Learn/input source mode | Opens **slice menu** for active sample | Hold **Shift + LEARN** |

### Behavior changes

- **New samples default to STRETCH** — when you drop any sample in, it automatically time-stretches to the current BPM. No more hunting through menus to turn this on.
- **OLED shows your language** — buttons flash SAMPLES, AUDIO CLIP, SLICE instead of MIDI, CV, LEARN/INPUT.

### What hasn't changed

Everything else is stock community firmware 1.2.1. All original features accessible via Shift combos.

---

## How to make an audio clip (the new way)

**Before (stock — 6 steps):**
1. Make a new clip
2. In Song View, press and hold a pad
3. Click Select
4. Use Learn + Row Pad to select input source
5. Configure inL / inR / inLR
6. Clip streams audio

**Now (1 step):**
1. Press **CV button** (now labeled AUDIO)

The clip is created on your current row, monitoring is on, stereo line in is the default. If you want to change the input source: hold **LEARN + that row's pad** to pick inL, inR, inLR, etc.

---

## How to slice a sample (the new way)

**Before (stock — many steps):**
- Navigate into sample editor → shift-select → find slice menu → configure

**Now (1 step):**
1. Select the clip/row with your sample
2. Press **LEARN button** (now labeled SLICE)

Slice menu opens immediately. Chop mode (transient / step / lazy) toggled from inside.
When you're happy with slices, confirm → you'll be prompted to name the kit.

---

## How to change stretch/pitched/raw mode

When you're on a sample clip, press **SAMPLES button** (was MIDI) to browse more samples.

To toggle the playback mode of the **current** sample between Stretch, Pitched, and Raw:
*(This shortcut TBD — next firmware update)*

The OLED top-right corner always shows the current default: **STRETCH**, **PITCHED**, or **RAW**.

---

## Song structure conventions

*(Reminder to self — these are workflow notes, not firmware changes yet)*

- **Bottom row** = song sections: pad 1 = Intro, pad 2 = Verse, pad 3 = Chorus, etc.
- **Build upward** from bottom row — new loops stack above the section pads
- Section pads named: INTRO / VERSE / CHORUS / BRIDGE / OUTRO

---

## Building this firmware yourself

### One-time setup

1. Go to [github.com](https://github.com) → sign up (free)
2. Go to `https://github.com/YOUR-USERNAME/DelugeFirmware` (your fork)
3. Click green **Code** button → **Codespaces** tab → **Create codespace on community**
4. Wait ~2 min for the environment to load

### Every time you want to make a change or rebuild

1. Open your Codespace (reopen from github.com — it remembers everything)
2. In the terminal at the bottom, paste this and hit Enter:

```bash
bash apply_aaron_mods.sh
```

3. When it finishes, paste this and hit Enter:

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build --parallel
```

4. Wait 3–5 minutes
5. In the left sidebar, open `build/` folder → right-click `deluge.bin` → **Download**

### Flashing to your Deluge

1. **Back up your SD card** (copy everything to your computer)
2. Copy `deluge.bin` to the **root** of your SD card (not in any folder)
3. Put SD card back in Deluge
4. **Hold the Select knob while powering on** → progress bar appears → reboots when done

### Going back to stock firmware

Download the official `.bin` from:
`https://github.com/SynthstromAudible/DelugeFirmware/releases`

Flash it the same way. You're back to stock in 60 seconds.

---

## Files in this repo

| File | What it is |
|------|-----------|
| `apply_aaron_mods.sh` | Run this in Codespaces to apply all your mods automatically |
| `README_AARON.md` | This file — your personal notes |
| `src/` | The actual firmware source code |

---

## Mod history

| Date | Change |
|------|--------|
| Mar 2026 | Initial remaps: MIDI→SAMPLES, CV→AUDIO CLIP, LEARN→SLICE |
| Mar 2026 | Default sample mode set to STRETCH |
| Mar 2026 | OLED strings updated to match new button purposes |

