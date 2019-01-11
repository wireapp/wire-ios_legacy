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

CONFIGURATION_LOCATION=Configuration
PUBLIC_CONFIGURATION_REPO=https://github.com/wireapp/wire-ios-build-configuration.git
REPO_URL=$PUBLIC_CONFIGURATION_REPO

OVERRIDES_DIR=

usage()
{
    echo "usage: download_assets.sh [[--configuration_repo repo_url] | [--override_with path] | [-h]]"
}


while [ "$1" != "" ]; do
    case $1 in
        --configuration_repo )  shift
                                echo "Using custom configuration repository: $@"
                                REPO_URL=$@
                                break
                                ;;
        --override_with )       shift
                                echo "Overriding with configuration files in $@"
                                OVERRIDES_DIR=$@
                                break
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

##################################
# Checout assets
##################################
if [ -e "${CONFIGURATION_LOCATION}" ]; then
    pushd ${CONFIGURATION_LOCATION} &> /dev/null
    echo "Pulling configuration..."
    git stash --include-untracked # Stash in case there are some changes here
    git pull
    popd &> /dev/null
else
    git ls-remote "${REPO_URL}" &> /dev/null
    if [ "$?" -ne 0 ]; then
        echo "Cannot access configuration repository!"
        exit -1
    fi 

    echo "Cloning assets from ${REPO_URL}"
    git clone --depth 1 ${REPO_URL} ${CONFIGURATION_LOCATION}
fi

if [ ! -z "${OVERRIDES_DIR}" ]; then
    # Add trailing slash if not present so that cp would copy contents of directory
    [[ "${OVERRIDES_DIR}" != */ ]] && OVERRIDES_DIR="${OVERRIDES_DIR}/"
    echo "Copying '${OVERRIDES_DIR}' over to '${CONFIGURATION_LOCATION}'"
    cp -R "${OVERRIDES_DIR}" "${CONFIGURATION_LOCATION}"
fi


