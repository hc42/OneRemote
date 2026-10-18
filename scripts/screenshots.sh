#!/usr/bin/env bash
# Takes the App Store screenshots with the UI test "ScreenshotTests" (simulated amplifier, no hardware).
#
#   scripts/screenshots.sh          iPhone 6.9" and iPad 13" (the sizes the App Store requires)
#
# Environment:
#   IPHONE="iPhone 17 Pro Max"      simulator names; default: the newest "Pro Max" iPhone and the newest 13-inch iPad Pro
#   IPAD="iPad Pro 13-inch (M5)"
#
# The images end up in build/screenshots/<device>/ as 01-Controls.png and so on.
# Mac screenshots are taken by hand (Cmd+Shift+4, then Space, then click the window).

set -uo pipefail
cd "$(dirname "$0")/.."

OUT="build/screenshots"
RESULTS="build/test-results"
mkdir -p "$OUT" "$RESULTS"

command -v xcodegen >/dev/null || { echo "xcodegen is missing: brew install xcodegen" >&2; exit 2; }
xcodegen generate --quiet || exit 1

# find_sim <name pattern> -> "name|udid" of the last (= newest) matching available simulator
find_sim() {
    xcrun simctl list devices available \
        | sed -nE 's/^ +(.*[^ ]) \(([0-9A-F-]{36})\) \((Booted|Shutdown)\).*/\1|\2/p' \
        | grep -E "$1" | tail -1
}

pick() { # pick <given name> <pattern>
    if [ -n "$1" ]; then find_sim "^$(printf '%s' "$1" | sed 's/[][()*.]/\\&/g')\|"; else find_sim "$2"; fi
}

DEVICES=()
iphone="$(pick "${IPHONE:-}" '^iPhone [^|]*Pro Max\|')"
ipad="$(pick "${IPAD:-}" '^iPad Pro 13-inch[^|]*\|')"
[ -n "$iphone" ] && DEVICES+=("$iphone") || echo "No Pro Max iPhone simulator found" >&2
[ -n "$ipad" ] && DEVICES+=("$ipad") || echo "No 13-inch iPad Pro simulator found" >&2
[ ${#DEVICES[@]} -gt 0 ] || exit 1

FAILED=0
for entry in "${DEVICES[@]}"; do
    name="${entry%%|*}"; udid="${entry##*|}"
    slug="$(printf '%s' "$name" | tr ' ()' '-' | tr -s '-')"
    bundle="$RESULTS/Screenshots-$slug.xcresult"
    dir="$OUT/$slug"
    echo
    echo "=== $name ==="
    rm -rf "$bundle" "$dir"; mkdir -p "$dir"
    xcrun simctl boot "$udid" 2>/dev/null || true
    xcrun simctl bootstatus "$udid" -b >/dev/null 2>&1
    # The usual store look: 9:41, full battery and signal
    xcrun simctl status_bar "$udid" override --time "9:41" --batteryState charged --batteryLevel 100 \
        --cellularMode active --cellularBars 4 --wifiBars 3 >/dev/null 2>&1 || true

    xcodebuild test -project OneRemote.xcodeproj -scheme OneRemote -testPlan Screenshots \
        -destination "platform=iOS Simulator,id=$udid" -resultBundlePath "$bundle" \
        > "$RESULTS/Screenshots-$slug.log" 2>&1
    grep -E "error:|TEST (SUCCEEDED|FAILED)" "$RESULTS/Screenshots-$slug.log" | grep -v IDE

    tmp="$(mktemp -d)"
    xcrun xcresulttool export attachments --path "$bundle" --output-path "$tmp" >/dev/null 2>&1
    python3 - "$tmp" "$dir" <<'PY'
import json, os, re, shutil, sys
src, dst = sys.argv[1], sys.argv[2]
with open(os.path.join(src, "manifest.json")) as f:
    manifest = json.load(f)
n = 0
for test in manifest:
    for a in test.get("attachments", []):
        m = re.match(r"(\d\d-[A-Za-z-]+)", a.get("suggestedHumanReadableName", ""))
        if m:
            shutil.copy(os.path.join(src, a["exportedFileName"]), os.path.join(dst, m.group(1) + ".png"))
            n += 1
print(f"{n} screenshots in {dst}")
PY
    [ -n "$(ls "$dir" 2>/dev/null)" ] || FAILED=1
    xcrun simctl status_bar "$udid" clear >/dev/null 2>&1 || true
    rm -rf "$tmp"
done

echo
[ "$FAILED" = 0 ] && echo "Done: $OUT" || echo "Some devices produced no screenshots (see $RESULTS/Screenshots-*.log)"
exit "$FAILED"
