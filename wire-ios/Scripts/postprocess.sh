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

POSTPROCESS_SCRIPT="Configuration/postprocess.sh"

if [ -e "${POSTPROCESS_SCRIPT}" ]; then
    echo "Running ${POSTPROCESS_SCRIPT}"
    ./"${POSTPROCESS_SCRIPT}"
else
    echo "No postprocess script found in ${POSTPROCESS_SCRIPT}, skipping..."
fi

echo "✅  Postprocess Done"
