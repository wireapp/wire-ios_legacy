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


set -e
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR/..

source avs-versions
AVS_FRAMEWORK_NAME="avs.framework"

##################################
# CREDENTIALS
##################################
# prepare credentials if needed
if [[ -n "${GITHUB_ACCESS_TOKEN}" ]]; then
	ACCESS_TOKEN_QUERY="?access_token=${GITHUB_ACCESS_TOKEN}"
fi

##################################
# SET UP PATHS
##################################
AVS_LOCAL_PATH="wire-avs-ios"

if [[ -n "${AVS_REPO}" ]]; then
	echo "ℹ️  Using custom AVS binary"
	AVS_VERSION="${AVS_CUSTOM_VERSION}"
	if [ -z "${AVS_VERSION}" ]; then
		AVS_VERSION="${APPSTORE_AVS_VERSION}"
	fi
else 
	echo "ℹ️  No custom AVS binary specified"
	exit 0
fi

##################################
# VERSIONS TO DOWNLOAD
##################################
# if version is not specified, get the latest
if [ -z "${AVS_VERSION}" ]; then
	LATEST_VERSION_PATH="https://api.github.com/repos/${AVS_REPO}/releases/latest"
	# need to get tag of last version
	AVS_VERSION=`curl -sLJ "${LATEST_VERSION_PATH}${ACCESS_TOKEN_QUERY}" | python -c 'import json; import sys; print json.load(sys.stdin)["tag_name"]'`
	if [ -z "${AVS_VERSION}" ]; then
		echo "❌  Can't find latest version for ${LATEST_VERSION_PATH} ⚠️"
		exit 1
	fi
	echo "ℹ️  Latest version is ${AVS_VERSION}"
fi

AVS_FILENAME="${AVS_FRAMEWORK_NAME}-${AVS_VERSION}.zip"
AVS_RELEASE_TAG_PATH="https://api.github.com/repos/${AVS_REPO}/releases/tags/${AVS_VERSION}"

##################################
# SET UP FOLDERS
##################################
LIBS_PATH=./Libraries
CARTHAGE_BUILD_PATH=./Carthage/Build/iOS

pushd $CARTHAGE_BUILD_PATH > /dev/null

# remove previous, will unzip new
rm -fr $AVS_FRAMEWORK_NAME > /dev/null
rm -fr "${AVS_FRAMEWORK_NAME}.dSYM" > /dev/null

##################################
# DOWNLOAD
##################################
if [ -e "${AVS_FILENAME}" ]; then
	# file already there? Just unzip it 
	echo "ℹ️  Existing archive ${AVS_FILENAME} found, skipping download"
else
	# DOWNLOAD
	echo "ℹ️  Downloading ${AVS_RELEASE_TAG_PATH}..."
	
	# Get tag json: need to parse json to get assed URL
	TEMP_FILE=`mktemp`
	curl -sLJ "${AVS_RELEASE_TAG_PATH}${ACCESS_TOKEN_QUERY}" -o "${TEMP_FILE}"
	ASSET_URL=`cat ${TEMP_FILE} | python -c 'import json; import sys; print json.load(sys.stdin)["assets"][1]["url"]'`
	rm "${TEMP_FILE}"
	if [ -z "${ASSET_URL}" ]; then
		echo "❌  Can't fetch release ${AVS_VERSION} ⚠️"
	fi
	# get file
	TEMP_FILE=`mktemp`
	echo "Redirected to ${ASSET_URL}..."
	curl -LJ "${ASSET_URL}${ACCESS_TOKEN_QUERY}" -o "${TEMP_FILE}" -H "Accept: application/octet-stream"
	if [ ! -f "${TEMP_FILE}" ]; then
		echo "❌  Failed to download ${ASSET_URL} ⚠️"
		exit 1
	fi
	mv "${TEMP_FILE}" "${AVS_FILENAME}" > /dev/null
	echo "✅  Done downloading!"
fi

##################################
# UNPACK
##################################
echo "ℹ️  Installing in ${CARTHAGE_BUILD_PATH}/${AVS_FRAMEWORK_NAME}..."
mkdir "${AVS_FRAMEWORK_NAME}"

if ! unzip "${AVS_FILENAME}" "Carthage/Build/iOS/*" > /dev/null; then
	rm -fr "${AVS_FILENAME}"
	echo "❌  Failed to install, is the downloaded file valid? ⚠️"
	exit 1
fi

if ! mv "${CARTHAGE_BUILD_PATH}/${AVS_FRAMEWORK_NAME}" .; then
	rm -rf "Carthage"
	echo "❌  Failed to unpack framework, is the downloaded file valid? ⚠️"
	exit 1
fi

if ! mv "${CARTHAGE_BUILD_PATH}/${AVS_FRAMEWORK_NAME}.dSYM" .; then
	echo "ℹ️  Debug symbols not found, crash reports will have to be symbolicated manually! ⚠️"
fi

rm -rf "Carthage"

echo "✅  Done"

popd  > /dev/null
