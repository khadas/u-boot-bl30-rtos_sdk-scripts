#!/bin/bash
#
# Copyright (c) 2021-2022 Amlogic, Inc. All rights reserved.
#
# SPDX-License-Identifier: MIT
#

###############################################################
# Function: generate build combination.
###############################################################

# $1: "arch soc board product"
check_project()
{
	LINE_NR=`sed -n '$=' $BUILD_COMBINATION`
	i=0
	while IFS= read -r LINE; do
		[[ "$1" == "$LINE" ]] && break
		i=$((i+1))
	done < $BUILD_COMBINATION
	[ $i -ge $LINE_NR ] && $i && return 1

	return 0
}

# $1: arch
# $2: soc
# $3: board
# $4: product
check_build_combination()
{
	i=0
	for arch in ${ARCHS[*]}; do
		[[ "$1" == "$arch" ]] && break
		i=$((i+1))
	done
	[ $i -ge ${#ARCHS[*]} ] && return 1

	i=0
	for soc in ${SOCS[*]};do
		[[ "$2" == "$soc" ]] && break
		i=$((i+1))
	done
	[ "$i" -ge ${#SOCS[*]} ] && return 2

	i=0
	for board in ${BOARDS[*]};do
		[[ "$3" == "$board" ]] && break
		i=$((i+1))
	done
	[ "$i" -ge ${#BOARDS[*]} ] && return 3

	i=0
	for product in ${PRODUCTS[*]};do
		[[ "$4" == "$product" ]] && break
		i=$((i+1))
	done
	[ "$i" -ge ${#PRODUCTS[*]} ] && return 4

	return 0
}

unset ARCHS SOCS BOARDS PRODUCTS

ARCHS=($(find $PWD/arch -mindepth 1 -maxdepth 1 -type d ! -name ".*" | xargs basename -a | sort -n))
SOCS=($(find $PWD/soc -mindepth 2 -maxdepth 2 -type d ! -name ".*" | xargs basename -a | sort -n))
BOARDS=($(find $PWD/boards -mindepth 2 -maxdepth 2 -type d ! -name ".*" | xargs basename -a | sort -n))
PRODUCTS=($(find $PWD/products -mindepth 1 -maxdepth 1 -type d ! -name ".*" | xargs basename -a | sort -n))

BUILD_COMBINATION_INPUT="$PWD/build_system/build_combination.in"
export BUILD_COMBINATION="$PWD/output/build_combination.txt"

if [ ! -d "$PWD/output" ]; then
	mkdir -p $PWD/output
fi
if [ ! -s "$BUILD_COMBINATION" ] || [ $BUILD_COMBINATION -ot $BUILD_COMBINATION_INPUT ]; then
	:> $BUILD_COMBINATION
	while IFS= read -r LINE; do
		arch=`echo "$LINE"|awk '{print $1}'`
		soc=`echo "$LINE"|awk '{print $2}'`
		board=`echo "$LINE"|awk '{print $3}'`
		product=`echo "$LINE"|awk '{print $4}'`
		check_build_combination $arch $soc $board $product
		[ "$?" -eq 0 ] && echo $LINE >> $BUILD_COMBINATION
	done < $BUILD_COMBINATION_INPUT
fi
