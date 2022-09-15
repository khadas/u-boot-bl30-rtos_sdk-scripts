#!/bin/bash
#
# Copyright (c) 2021-2022 Amlogic, Inc. All rights reserved.
#
# SPDX-License-Identifier: MIT
#

# Clear build.log
cat <<EOF > $BUILD_LOG
EOF

source scripts/publish.sh

function get_new_package_dir() {
	filelist=$(ls -t output/packages)
	fileArry=($filelist)
	CURRENT_PRODUCTS_DIR_NAME=${fileArry[0]}
	export CURRENT_PRODUCTS_DIR_NAME
}

echo "======== Building all packages ========" | tee -a $BUILD_LOG

source scripts/gen_package_combination.sh

index=0
while IFS= read -r LINE; do
	source scripts/pkg_env.sh $index gen_all >> $BUILD_LOG 2>&1
	[ "$?" -ne 0 ] && echo "Ignore unsupported combination!" && continue
	echo -n "$index. Building ... "
	make package >> $BUILD_LOG 2>&1
	get_new_package_dir
	[ "$?" -ne 0 ] && echo "failed!" && cat $BUILD_LOG && echo -e "\nAborted with errors!\n" && exit 3
	grep -qr "warning: " $BUILD_LOG
	[ "$?" -eq 0 ] && cat $BUILD_LOG && echo -e "\nAborted with warnings!\n" && exit 1
	echo "OK."
	if [[ "$SUBMIT_TYPE" == "release" ]]; then
		publish_packages >> $BUILD_LOG 2>&1
		[ "$?" -ne 0 ] && echo "Failed to publish packages!" && exit 4
	fi
	index=$((index + 1))
done <"$PACKAGE_COMBINATION"

[[ "$SUBMIT_TYPE" == "release" ]] && post_publish_packages >> $BUILD_LOG 2>&1

echo -e "======== Done ========\n" | tee -a $BUILD_LOG
