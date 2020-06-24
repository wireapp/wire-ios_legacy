#!/bin/bash
#
# Wire
# Copyright (C) 2020 Wire Swiss GmbH
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
# ----------------------------------------------------------------------


#
# USAGE:
# This scripts checks that the necessary tools are installed on the local machine
# and sets up the project so that it can be built with Xcode
#

set -e

function die { ( >&2 echo "$*"); exit 1; }

# CHECK PREREQUISITES
hash carthage 2>/dev/null || die "Can't find Carthage, please install from https://github.com/Carthage/Carthage"
hash xcodebuild 2>/dev/null || die "Can't find Xcode, please install from the App Store"

version=`carthage version | tail -n 1`
CARTHAGE_VERSION=( ${version//./ } )
version=`xcodebuild -version | head -n 1 | sed "s/Xcode //"`
XCODE_VERSION=( ${version//./ } )

[[ ${CARTHAGE_VERSION[0]} -gt 0 || ${CARTHAGE_VERSION[1]} -ge 29 ]] || die "Carthage should be at least version 0.29"
[[ ${XCODE_VERSION[0]} -gt 11 || ( ${XCODE_VERSION[0]} -eq 11 && ${XCODE_VERSION[1]} -ge 4 ) ]] || die "Xcode version should be at least 11.4.0. The current version is ${XCODE_VERSION}"

# SETUP
echo "ℹ️  Carthage bootstrap. This might take a while..."
carthage bootstrap --platform ios &
echo ""

echo "ℹ️  Downloading AVS library..."
./Scripts/download-avs.sh &
echo ""

echo "ℹ️  Downloading additional assets..."
./Scripts/download-assets.sh "$@" &
echo ""

echo "ℹ️  [CodeGen] Update StyleKit Icons..."
swift run --package-path Scripts/updateStylekit &
echo ""

echo "ℹ️  Update Licenses File..."
swift run --package-path ./Scripts/updateLicenses &
echo ""

wait

echo "ℹ️  Doing additional postprocessing..."
./Scripts/postprocess.sh
echo ""

echo "✅  Wire project was set up, you can now open Wire-iOS.xcodeproj"
