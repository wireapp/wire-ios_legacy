#!/bin/sh

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

if [[ $# -eq 0 ]] ; then
    echo 'Strip bitcode from frameworks.'
	echo 'Usage:'
	echo "$0 frameworks-folder code-signing-identity"
    exit 0
fi

if [ "$PLATFORM_NAME" == "iphonesimulator" ] ; then
	echo 'Not necessary to strip for simulator.'
	exit 0
fi

if [ "$CONFIGURATION" == "Debug" ] ; then
	echo 'Not necessary to strip for debug.'
	exit 0
fi

TMPDIR=tmp-bitcode
mkdir $TMPDIR
cd $TMPDIR
for FMWK_FULL in $1/*.framework; do
FMWK=$(basename $FMWK_FULL)
echo Removing bitcode from $FMWK
FMWK_NAME=${FMWK%.*}
xcrun bitcode_strip -r "$FMWK_FULL/$FMWK_NAME" -o $FMWK_NAME
mv $FMWK_NAME "$FMWK_FULL/$FMWK_NAME"
if [[ "$CODE_SIGNING_REQUIRED" -eq YES ]];
then
codesign --force --sign "$2" --preserve-metadata=identifier,entitlements,resource-rules "$FMWK_FULL/$FMWK_NAME"
fi
done
cd ..
rm -rf $TMPDIR
