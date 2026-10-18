#!/usr/bin/env bash
# Runs the automated tests from the command line.
#
#   scripts/test.sh            everything: unit tests (macOS) and UI tests (iPhone simulator)
#   scripts/test.sh unit       unit tests only (macOS)
#   scripts/test.sh ui         UI tests only (iPhone simulator)
#   scripts/test.sh mac        unit tests on the Mac only (fastest)
#   scripts/test.sh macui      UI tests on the Mac only
#
# Environment:
#   SIMULATOR="iPhone 16"      simulator to use (default: the first available iPhone)
#   UNIT_ON_IPHONE=1           also run the unit tests in the iPhone simulator
#   UI_ON_MAC=1                with "all" or "ui": also run the UI tests on the Mac
#
# The suites are defined by the test plans in TestPlans/ (Unit, UI, All); the same plans can be
# chosen in Xcode (scheme > Test) or run directly: xcodebuild test -scheme OneRemote -testPlan All ...
#
# Needs Xcode and XcodeGen (brew install xcodegen). Exit code 0 only if every run passed.

set -uo pipefail
cd "$(dirname "$0")/.."

MODE="${1:-all}"
SCHEME="OneRemote"
PROJECT="OneRemote.xcodeproj"
RESULTS="build/test-results"
FAILED=()

case "$MODE" in all|unit|ui|mac|macui) ;; *) echo "Usage: $0 [all|unit|ui|mac|macui]" >&2; exit 2 ;; esac

command -v xcodegen >/dev/null || { echo "xcodegen is missing: brew install xcodegen" >&2; exit 2; }
xcodegen generate --quiet || { echo "xcodegen failed" >&2; exit 1; }

# The simulator: SIMULATOR if set, otherwise the first available iPhone
simulator_name() {
    if [ -n "${SIMULATOR:-}" ]; then echo "$SIMULATOR"; return; fi
    xcrun simctl list devices available \
        | sed -nE 's/^ +(iPhone[^()]*[^ ()]) \([0-9A-F-]{36}\).*/\1/p' | head -1
}
SIM="$(simulator_name)"

# Without xcpretty the full log goes to a file and only the important lines are shown
summarize() {
    # Failure messages can span several lines (element tree): show a few lines after each "error:"
    awk '/IDESchemeActionSDKRecord/ {next}
         /error:/ {print; keep=6; next}
         keep>0 {print; keep--; next}
         /Test Suite .All tests|Executed [0-9]+ tests|Failing tests|TEST (SUCCEEDED|FAILED)|BUILD FAILED/ {print}
         /^[[:space:]]+[A-Za-z]+\.test/ {print}'
}

# run <title> <destination> <extra xcodebuild args...>
run() {
    local title="$1" destination="$2"; shift 2
    local bundle="$RESULTS/${title// /-}.xcresult"
    rm -rf "$bundle"
    echo
    echo "=== $title ==="
    local log="$RESULTS/${title// /-}.log"
    if command -v xcpretty >/dev/null; then
        xcodebuild test -project "$PROJECT" -scheme "$SCHEME" -destination "$destination" \
            -resultBundlePath "$bundle" "$@" 2>&1 | tee "$log" | xcpretty
    else
        xcodebuild test -project "$PROJECT" -scheme "$SCHEME" -destination "$destination" \
            -resultBundlePath "$bundle" "$@" > "$log" 2>&1
        summarize < "$log"
    fi
    # the pipes hide xcodebuild's exit status: look at the result bundle instead
    if [ -d "$bundle" ] && xcrun xcresulttool get test-results summary --path "$bundle" 2>/dev/null \
        | grep -q '"result" *: *"Passed"'; then
        echo "PASSED: $title"
    else
        echo "FAILED: $title   (details: open $bundle)"
        FAILED+=("$title")
    fi
}

mkdir -p "$RESULTS"

if [ "$MODE" = "mac" ] || [ "$MODE" = "unit" ] || [ "$MODE" = "all" ]; then
    run "Unit tests macOS" "platform=macOS" -testPlan Unit
fi

if [ "$MODE" = "macui" ]; then
    run "UI tests macOS" "platform=macOS" -testPlan UI
elif [ "$MODE" != "mac" ]; then
    if [ -z "$SIM" ]; then
        echo "No iPhone simulator found (Xcode > Settings > Platforms)" >&2
        FAILED+=("iPhone simulator missing")
    else
        IOS="platform=iOS Simulator,name=$SIM"
        # The unit tests are platform independent and already run on the Mac; UNIT_ON_IPHONE=1 repeats them
        if [ "${UNIT_ON_IPHONE:-0}" = "1" ] && { [ "$MODE" = "unit" ] || [ "$MODE" = "all" ]; }; then
            run "Unit tests iPhone" "$IOS" -testPlan Unit
        fi
        if [ "$MODE" = "ui" ] || [ "$MODE" = "all" ]; then
            run "UI tests iPhone" "$IOS" -testPlan UI
        fi
    fi
    if [ "${UI_ON_MAC:-0}" = "1" ] && { [ "$MODE" = "ui" ] || [ "$MODE" = "all" ]; }; then
        run "UI tests macOS" "platform=macOS" -testPlan UI
    fi
fi

echo
if [ ${#FAILED[@]} -eq 0 ]; then
    echo "All test runs passed."
    exit 0
fi
echo "Failed: ${FAILED[*]}"
exit 1
