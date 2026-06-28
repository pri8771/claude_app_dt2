#!/usr/bin/env bash
set -euo pipefail

# Anjali local build & test validation harness.
# Run from anywhere: ./Scripts/build.sh
# Override the simulator with: DESTINATION="platform=iOS Simulator,name=iPhone 16" ./Scripts/build.sh

cd "$(dirname "$0")/.."

PROJECT="Anjali/Anjali.xcodeproj"
SCHEME="Anjali"
DESTINATION="${DESTINATION:-platform=iOS Simulator,name=iPhone 15}"
REPORTS="BuildReports"
BUILD_LOG="$REPORTS/build.log"
TEST_LOG="$REPORTS/test.log"

mkdir -p "$REPORTS"

echo "=== Environment ==="
date
if command -v sw_vers >/dev/null 2>&1; then
  sw_vers
else
  echo "sw_vers not available (not macOS?) — xcodebuild steps will not run here."
fi
if command -v xcodebuild >/dev/null 2>&1; then
  xcodebuild -version
else
  echo "xcodebuild not found — install Xcode 16+ and run this on macOS."
fi
echo "Destination: $DESTINATION"
echo ""

echo "=== Content validation ==="
python3 Scripts/validate_prayers.py
echo ""

echo "=== Project targets/schemes ==="
xcodebuild -list -project "$PROJECT"
echo ""

echo "=== Build (full log -> $BUILD_LOG) ==="
set -o pipefail
xcodebuild -project "$PROJECT" -scheme "$SCHEME" \
  -destination "$DESTINATION" clean build 2>&1 | tee "$BUILD_LOG"
echo ""

echo "=== Test (full log -> $TEST_LOG) ==="
set -o pipefail
xcodebuild -project "$PROJECT" -scheme "$SCHEME" \
  -destination "$DESTINATION" test 2>&1 | tee "$TEST_LOG"
echo ""

echo "=== Success ==="
echo "Build and tests completed. Logs: $BUILD_LOG, $TEST_LOG"
