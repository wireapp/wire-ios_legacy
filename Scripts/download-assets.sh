#!/bin/bash

#
# Wire
# Copyright (C) 2016 Wire Swiss GmbH
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



DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR/..


REPO_NAME=wire-ios-build-assets
REPO_URL=github.com:wireapp/${REPO_NAME}.git

##################################
# Checout assets
##################################
if [ -e "${REPO_NAME}" ]; then
	cd ${REPO_NAME}
	echo "Pulling assets..."
	git pull
else
	git ls-remote "git@${REPO_URL}" &> /dev/null
	if [ "$?" -ne 0 ]; then
		echo "No access to assets"
	else 
		echo "Cloning assets..."
		git clone --depth 1 git@${REPO_URL}
	fi
fi
