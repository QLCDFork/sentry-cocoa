#!/bin/bash

# For available Xcode versions see:
# - https://github.com/actions/runner-images/blob/main/images/macos/macos-13-Readme.md
# - https://github.com/actions/runner-images/blob/main/images/macos/macos-14-Readme.md

set -euo pipefail

# 14.3 is the default
XCODE_VERSION="${1:-14.3}"

sudo xcode-select -s "/Applications/Xcode_${XCODE_VERSION}.app/Contents/Developer"
swiftc --version
