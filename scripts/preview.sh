#!/usr/bin/env zsh
set -euo pipefail

app_path="build/Build/Products/Release/spac.app"

killall spac >/dev/null 2>&1 || true

xcodebuild -scheme spac \
	-configuration Release \
	-derivedDataPath build

open "$app_path"
