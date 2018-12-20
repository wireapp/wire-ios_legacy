#!/bin/bash

#
# Wire
# Copyright (C) 2018 Wire Swiss GmbH
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

set -e
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR/..

ORIGINAL_TRANSLATIONS="Wire-iOS/Resources"
MODIFIED_TRANSLATIONS="Configuration/Translations"

if [ -e "${MODIFIED_TRANSLATIONS}" ]; then
    ./Scripts/compare-translations.py "${ORIGINAL_TRANSLATIONS}" "${MODIFIED_TRANSLATIONS}" --copy-to "${ORIGINAL_TRANSLATIONS}" --ignore-missing
else
    echo "No need to modify any translations, skipping..."
fi

echo "✅  Done"
