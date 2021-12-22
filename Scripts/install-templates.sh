#!/bin/bash

#
# Wire
# Copyright (C) 2021 Wire Swiss GmbH
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
# along with this program. If not, see http://www.gnu.org/licenses/.
#

# Move to root directory.
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR/..

# Determine source and destination paths.
SOURCE=Templates/Viper
XCODE_PATH=$(xcode-select -p)
DESTINATION=$XCODE_PATH/Library/Xcode/Templates/File\ Templates/

# Install
echo "Installing '${SOURCE}' to '${DESTINATION}'"
cp -r "$SOURCE" "$DESTINATION"
