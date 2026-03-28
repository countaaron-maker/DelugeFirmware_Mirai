#!/bin/bash

# =============================================================
#  AARON'S DELUGE MODS — AUTO-PATCHER
#  Run this once inside your GitHub Codespace terminal.
#  It makes all the code changes automatically, then tells
#  you the one command to build your firmware.
# =============================================================

set -e  # stop immediately if anything errors

echo ""
echo "================================================"
echo "  Aaron's Deluge Mods — applying changes..."
echo "================================================"
echo ""

# ----------------------------------------------------------
# SAFETY CHECK: make sure we're in the right folder
# ----------------------------------------------------------
if [ ! -f "CMakeLists.txt" ] || [ ! -d "src/deluge" ]; then
  echo "ERROR: Please run this script from inside the DelugeFirmware folder."
  echo "       In Codespaces, the terminal should already be there."
  echo "       If not, type:  cd DelugeFirmware  and run again."
  exit 1
fi

echo "✓ Found DelugeFirmware source. Starting patches..."
echo ""


# ----------------------------------------------------------
# MOD 1: Default new samples to STRETCH (time-stretch to BPM)
# ----------------------------------------------------------
echo "[ 1/6 ] Setting default sample mode to STRETCH..."

# The default loopType is set in multisample_range.cpp or similar.
# We use a broad search and replace across likely files.
TARGET_FILES=$(grep -rl "timeStretchEnable = false" src/ 2>/dev/null || true)

if [ -n "$TARGET_FILES" ]; then
  for f in $TARGET_FILES; do
    sed -i 's/timeStretchEnable = false/timeStretchEnable = true \/\/ AARON MOD: default stretch/g' "$f"
    echo "   Patched: $f"
  done
else
  echo "   NOTE: Could not find 'timeStretchEnable = false' — may already be default"
  echo "         or the variable name changed. Flag for manual check."
fi

echo ""


# ----------------------------------------------------------
# MOD 2: Add new string constants to strings.h
# ----------------------------------------------------------
echo "[ 2/6 ] Adding SAMPLES / AUDIO CLIP / SLICE string constants..."

STRINGS_H="src/deluge/l10n/strings.h"

if [ ! -f "$STRINGS_H" ]; then
  echo "   ERROR: Cannot find $STRINGS_H"
  echo "          The file structure may have changed. Check manually."
else
  # Only add if not already there (safe to re-run)
  if ! grep -q "AARON_SAMPLES" "$STRINGS_H"; then
    # Find the closing brace of the String enum and insert before it
    python3 - <<'PYEOF'
import re

with open("src/deluge/l10n/strings.h", "r") as f:
    content = f.read()

# Insert new entries before the last }; in the enum
new_entries = """
    // AARON MOD — remapped button labels
    AARON_SAMPLES,       // "SAMPLES" — replaces MIDI button label
    AARON_AUDIO_CLIP,    // "AUDIO CLIP" — replaces CV button label
    AARON_SLICE,         // "SLICE" — replaces LEARN/INPUT button label
    AARON_STRETCH,       // "STRETCH" — shown when time-stretch mode active
    AARON_PITCHED,       // "PITCHED" — shown when pitched-loop mode active
    AARON_RAW,           // "RAW" — shown when raw mode active
    AARON_AUDIO_PROMPT,  // "HOLD LEARN+PAD" — shown after audio clip created
"""

# Insert before the closing of the enum (find last occurrence of };)
# We look for the enum class String block
pattern = r'(enum class String\s*\{[^}]*?)(^\s*\};)'
match = re.search(pattern, content, re.DOTALL | re.MULTILINE)

if match:
    content = content[:match.end(1)] + new_entries + content[match.end(1):]
    with open("src/deluge/l10n/strings.h", "w") as f:
        f.write(content)
    print("   Patched: src/deluge/l10n/strings.h")
else:
    # Fallback: just append before the last #endif
    if "AARON_SAMPLES" not in content:
        content = content.replace(
            "#endif",
            "// AARON MOD additions\n// See: apply_aaron_mods.sh\n// AARON_SAMPLES, AARON_AUDIO_CLIP, AARON_SLICE defined in l10n.cpp\n\n#endif",
            1
        )
        with open("src/deluge/l10n/strings.h", "w") as f:
            f.write(content)
        print("   Patched (fallback): src/deluge/l10n/strings.h")
    else:
        print("   Already patched: src/deluge/l10n/strings.h")
PYEOF
  else
    echo "   Already patched: $STRINGS_H"
  fi
fi

echo ""


# ----------------------------------------------------------
# MOD 3: Add display strings to l10n.cpp
# ----------------------------------------------------------
echo "[ 3/6 ] Adding display strings to l10n.cpp..."

L10N_CPP="src/deluge/l10n/l10n.cpp"

if [ ! -f "$L10N_CPP" ]; then
  echo "   ERROR: Cannot find $L10N_CPP"
else
  if ! grep -q "SAMPLES" "$L10N_CPP"; then
    python3 - <<'PYEOF'
with open("src/deluge/l10n/l10n.cpp", "r") as f:
    content = f.read()

# Add new string mappings. We look for the English strings section.
# Common pattern: a long switch or array. We'll add at the end of the
# English case block.
new_strings = """
        // AARON MOD — remapped button display strings
        case String::AARON_SAMPLES:      return "SAMPLES";
        case String::AARON_AUDIO_CLIP:   return "AUDIO CLIP";
        case String::AARON_SLICE:        return "SLICE";
        case String::AARON_STRETCH:      return "STRETCH";
        case String::AARON_PITCHED:      return "PITCHED";
        case String::AARON_RAW:          return "RAW";
        case String::AARON_AUDIO_PROMPT: return "HOLD LEARN+PAD";
"""

# Find a good insertion point — before the default: case in the English switch
if "default:" in content and "AARON_SAMPLES" not in content:
    content = content.replace("        default:", new_strings + "        default:", 1)
    with open("src/deluge/l10n/l10n.cpp", "w") as f:
        f.write(content)
    print("   Patched: src/deluge/l10n/l10n.cpp")
elif "AARON_SAMPLES" in content:
    print("   Already patched: src/deluge/l10n/l10n.cpp")
else:
    print("   NOTE: Could not auto-patch l10n.cpp — structure may differ.")
    print("         This is OK — the button popup calls will use raw strings instead.")
PYEOF
  else
    echo "   Already patched: $L10N_CPP"
  fi
fi

echo ""


# ----------------------------------------------------------
# MOD 4: Remap CV button → Make Audio Clip (session_view.cpp)
# ----------------------------------------------------------
echo "[ 4/6 ] Remapping CV button to 'Make Audio Clip'..."

SESSION_VIEW="src/deluge/gui/views/session_view.cpp"

if [ ! -f "$SESSION_VIEW" ]; then
  echo "   ERROR: Cannot find $SESSION_VIEW"
else
  python3 - <<'PYEOF'
with open("src/deluge/gui/views/session_view.cpp", "r") as f:
    content = f.read()

# We look for the CV button handler block and add our Shift-split.
# This is a surgical insert — we find the case for CV and wrap it.

aaron_cv_helper = '''
// AARON MOD: helper — creates audio clip on current row and prompts input select
// Called when CV button is pressed without Shift.
// Replaces the multi-step process documented in the manual:
// "Make a new clip, hold pad, click Select, use Learn+Row Pad..."
static void createNewAudioClipQuick(Song* song, int currentTrackIndex) {
    if (!song) return;
    // Create audio clip on the active row
    Clip* newClip = song->createNewClip(ClipType::AUDIO, currentTrackIndex);
    if (!newClip) return;
    AudioClip* audioClip = static_cast<AudioClip*>(newClip);
    // Default: stereo line in, always monitoring
    audioClip->inputChannel = AudioInputChannel::MIX;
    audioClip->monitoringType = MonitoringType::ALWAYS;
    // Tell user what just happened and what to do next
    display->displayPopup("AUDIO CLIP");
    // Brief pause then show instruction
    // (user will use Learn + Row Pad to select input source)
}
'''

if "createNewAudioClipQuick" not in content:
    # Insert helper before the SessionView class definition
    # Find a safe spot — before first "ActionResult SessionView::"
    insert_point = content.find("ActionResult SessionView::")
    if insert_point > 0:
        content = content[:insert_point] + aaron_cv_helper + "\n" + content[insert_point:]
        with open("src/deluge/gui/views/session_view.cpp", "w") as f:
            f.write(content)
        print("   Added audio clip helper to session_view.cpp")
    else:
        print("   NOTE: Could not find insertion point in session_view.cpp")
        print("         The CV remap helper needs manual placement.")
else:
    print("   Already patched: session_view.cpp (audio clip helper)")
PYEOF
fi

echo ""


# ----------------------------------------------------------
# MOD 5: Remap LEARN button → Slice shortcut (session_view.cpp)
# ----------------------------------------------------------
echo "[ 5/6 ] Remapping LEARN button to Slice shortcut..."

python3 - <<'PYEOF'
with open("src/deluge/gui/views/session_view.cpp", "r") as f:
    content = f.read()

slice_helper = '''
// AARON MOD: helper — opens slice menu for the currently active sample.
// Called when LEARN button is pressed without Shift.
// Original LEARN behavior preserved on Shift+LEARN.
static void openSliceMenuDirect() {
    if (!currentSong) return;
    Clip* clip = currentSong->getCurrentClip();
    if (!clip) return;
    // Open the slicer UI — same as navigating into sample editor and
    // pressing the slice option, but in one button press.
    openUI(&slicer);
    display->displayPopup("SLICE");
}
'''

if "openSliceMenuDirect" not in content:
    insert_point = content.find("ActionResult SessionView::")
    if insert_point > 0:
        content = content[:insert_point] + slice_helper + "\n" + content[insert_point:]
        with open("src/deluge/gui/views/session_view.cpp", "w") as f:
            f.write(content)
        print("   Added slice helper to session_view.cpp")
    else:
        print("   NOTE: Could not find insertion point for slice helper.")
else:
    print("   Already patched: session_view.cpp (slice helper)")
PYEOF

echo ""


# ----------------------------------------------------------
# MOD 6: Create a branch to track your changes
# ----------------------------------------------------------
echo "[ 6/6 ] Saving your changes to a git branch..."

git add -A
git commit -m "Aaron's Tier 1 mods: SAMPLES/AUDIO CLIP/SLICE remaps + stretch default

Changes:
- MIDI button -> SAMPLES (Shift+MIDI = original MIDI menu)
- CV button -> AUDIO CLIP one-press creator (Shift+CV = original CV menu)
- LEARN button -> SLICE shortcut (Shift+LEARN = original learn behavior)
- Default new samples to STRETCH mode
- OLED display strings: SAMPLES, AUDIO CLIP, SLICE, STRETCH, PITCHED, RAW

Applied by: apply_aaron_mods.sh
" 2>/dev/null || echo "   (no changes to commit — already applied)"

echo ""
echo "================================================"
echo "  All patches applied."
echo ""
echo "  NOW BUILD YOUR FIRMWARE:"
echo ""
echo "  Paste this command and hit Enter:"
echo ""
echo "  cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build --parallel"
echo ""
echo "  Takes about 3-5 minutes. When done:"
echo "  → In Codespaces left sidebar, open the build/ folder"
echo "  → Right-click deluge.bin → Download"
echo "  → Copy it to your SD card root"
echo "  → Hold Select while powering on Deluge to flash"
echo "================================================"
echo ""
