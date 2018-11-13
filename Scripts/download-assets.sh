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

CONFIGURATION_NAME=Configuration
PUBLIC_CONFIGURATION_REPO=git@github.com:wireapp/wire-ios-build-configuration.git

if [[ $# -eq 2 && $1 == "--configuration" ]]; then
	echo "Using custom configuration repository: $2"
	REPO_URL=$2
else
	REPO_URL=$PUBLIC_CONFIGURATION_REPO
fi

##################################
# Checout assets
##################################
if [ -e "${CONFIGURATION_NAME}" ]; then
	cd ${CONFIGURATION_NAME}
	echo "Pulling configuration..."
	git pull
else
	git ls-remote "${REPO_URL}" &> /dev/null
	if [ "$?" -ne 0 ]; then
		echo "No access to configuration repository, falling back to public"
		REPO_URL=$PUBLIC_CONFIGURATION_REPO
	fi 

	echo "Cloning assets from ${REPO_URL}"
	git clone --depth 1 ${REPO_URL} ${CONFIGURATION_NAME}
fi
