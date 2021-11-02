#!/bin/bash

###############################################################
# Function: Auto-generate root CMakeLists.txt and Kconfig according to manifest.xml.
###############################################################

if [ -f $dir/CMakeLists.txt ] && [ $manifest_file -ot $dir/CMakeLists.txt ]; then
	exit 0
fi

cmake_file="$PWD/CMakeLists.txt"
kconfig_file="$PWD/Kconfig"
exclude_dir="products"
special_dirs="arch soc boards"
drivers_dir="drivers"
dir=$PWD

if [ -n "$1" ]; then
	file_name=$1
else
	file_name="default.xml"
fi

while : ; do
	if [[ -n $(find $dir/.repo -name $file_name) ]]; then
		manifest_file=`find $dir/.repo -name $file_name`
		break
	fi
	dir=`dirname $dir`
	mountpoint -q $dir
	[ $? -eq 0 ] && break;
done

if [ ! -f $manifest_file ]; then
	echo "No such file: $file_name"
	exit 1
fi


if [ ! -f $dir/CMakeLists.txt ]; then
	echo "CMakeLists.txt and Kconfig Generated"
elif [ $manifest_file -nt $dir/CMakeLists.txt ]; then
	echo "CMakeLists.txt and Kconfig Updated"
fi

cat <<EOF > $cmake_file
enable_language(C CXX ASM)

target_include_directories(
	\${TARGET_NAME}
	PUBLIC
	include
)

EOF

cat <<EOF > $kconfig_file
EOF

absolute_prj_dir=$dir
if [[ $absolute_prj_dir == $PWD ]] ; then
	pattern="path="
else
	relative_prj_dir=`echo ${PWD#*${absolute_prj_dir}/}`
	pattern="path=\"${relative_prj_dir}/"
fi

while IFS= read -r line
do
	keyword=`echo "$line" | grep 'path=.* name=' | awk '{print $2}'`

	if [ $keyword ]; then
		repo_path=`echo ${keyword#*${pattern}} | sed 's/\"//g'`
		if [[ $repo_path == $drivers_dir* ]] ; then
			category=$repo_path
		else
			category=`dirname $repo_path`
		fi

		if [[ $repo_path == $exclude_dir/* ]] ; then
			continue
		fi

		# exclude other ARCH dirs
		case $special_dirs in
			*"$category"*) arch=`basename $repo_path`
				       if [ "$arch" == "$ARCH" ]; then
						cmake_path="$category/\${ARCH}"
						kconfig_path="$category/\$(ARCH)"
				       else
						continue
				       fi;;
			* ) cmake_path=$repo_path
			    kconfig_path=$repo_path;;
		esac

		# Generate root CMakeLists.txt
		if [ -f $repo_path/CMakeLists.txt ]; then
			echo "add_subdirectory($cmake_path)" >> $cmake_file
		fi

		# Generate root Kconfig
		if [ -f $repo_path/Kconfig ]; then
			if [ "$last_category" != "$category" ]; then
				if [ $last_category ]; then
					echo -e "endmenu\n" >> $kconfig_file
				fi
				echo "menu \"${category^} Options\"" >> $kconfig_file
			fi

			echo "source \"$kconfig_path/Kconfig\"" >> $kconfig_file
			last_category=$category
		fi
	fi
done < "$manifest_file"

echo "endmenu" >> $kconfig_file
