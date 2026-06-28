#!/bin/bash
set -e
cd "$(dirname "$0")/.."

echo "=== Anjali Build Validation ==="
xcodebuild -project Anjali/Anjali.xcodeproj -scheme Anjali \
  -destination 'platform=iOS Simulator,name=iPhone 15' clean build 2>&1 | tail -80

echo ""
echo "=== Running Tests ==="
xcodebuild -project Anjali/Anjali.xcodeproj -scheme Anjali \
  -destination 'platform=iOS Simulator,name=iPhone 15' test 2>&1 | tail -80
