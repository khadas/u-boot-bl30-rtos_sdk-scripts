#!/bin/bash
#
# Copyright (c) 2021-2022 Amlogic, Inc. All rights reserved.
#
# SPDX-License-Identifier: MIT
#

# usage:./scripts/build_all.sh at rtos sdk root dir

BUILD_COMBINATION="$PWD/scripts/build_combination.txt"
DOC_SERVER_PATH="ftp://platform:platform@10.68.11.163:2222/Documents/Ecosystem/RTOS/rtos-sdk/"

# Build and upload document
update_docoment()
{
	find -type f | while read filename
	do
		curl --ftp-create-dirs -T $filename $DOC_SERVER_PATH
		if [ $? -ne 0 ]; then
			return 1;
		fi
	done
}

if [[ "$SUBMIT_TYPE" == "daily" ]]; then
	make docs
	cd html
	update_docoment
	if [ $? -ne 0 ]; then
	    echo "Failed to update document"
	else
	    echo "Document updated!"
	fi
	cd -
fi

# Build all projects
i=0
while IFS= read -r LINE; do
	[[ "$i" -ne 0 ]] && echo ""
	i=$((i+1))
	source scripts/env.sh $LINE
	[ "$?" -ne 0 ] && echo "Failed to source scripts/env.sh!" && exit 1
	make distclean
	[ "$?" -ne 0 ] && echo "Failed to make distclean!" && exit 2
	make
	[ "$?" -ne 0 ] && echo "Failed to make!" && exit 3
	if [[ "$SUBMIT_TYPE" == "daily" ]]; then
		source scripts/scp.sh
		[ "$?" -ne 0 ] && echo "Failed to source scripts/scp.sh!" && exit 4
	fi
done < "$BUILD_COMBINATION"
