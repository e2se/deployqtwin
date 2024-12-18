#!/bin/bash
# deployqtwin.sh
# Finalize distributable as alternative to windeployqt
# 
# link: https://github.com/e2se/deployqtwin
# copyright: e2 SAT Editor Team
# author: Leonardo Laureti
# license: MIT License
# license: GNU GPLv3 License
# 

# private boolean _VERBOSE
_VERBOSE=false
# private boolean _SIMULATE
_SIMULATE=false
# private boolean _FORCE_OVERWRITE
_FORCE_OVERWRITE=false
# private string _INPUT_FILE
_INPUT_FILE=""
# private string _DEST_DIR
_DEST_DIR=""
# private string _ENVIRONMENT
_ENVIRONMENT="MSYS"
# private string _SYSTEM
_SYSTEM="MINGW64"
# private string _LIB_PATH
_LIB_PATH=""
# private string _QT_PATH
_QT_PATH=""
# private string _FRAMEWORK_PATH
_FRAMEWORK_PATH=""
# private string _PLUGINS_PATH
_PLUGINS_PATH=""
# private integer _QT_VER
_QT_VER=6
# private string _QT_VERSION
_QT_VERSION="6.8.0"
# private array _MODULES
_MODULES=("Core" "Gui" "Widgets")
# private array _PLUGINS
_PLUGINS=("platforms" "styles")
# private array _APPEND_LIBS
_APPEND_LIBS=()
# private boolean _DEPLOY_PLUGINS
_DEPLOY_PLUGINS=true

# private integer __QTVER
__QTVER=""
# private string __QTVERSION
__QTVERSION=""


usage () {
	if [[ -z "$1" ]]; then
		printf "%s\n\n" "Finalize distributable as alternative to windeployqt."
	fi

	printf "%s\n\n" "Usage: bash deployqtwin.sh binary.exe [OPTIONS]"
	printf "%s\n"   "Options:"
	printf "%s\n"   "--verbose                 Verbose"
	printf "%s\n"   "-s --simulate             Simulate actions without write files"
	printf "%s\n"   "-f --force                Force overwrite of files"
	printf "%s\n"   "-o --dest-path            Set a destination path instead of binary directory"
	printf "%s\n"   "-np --no-deploy-plugins   Disallow plugins deploy"
	printf "%s\n"   "-modules                  Modules to deploy (Core,Gui,Widgets)"
	printf "%s\n"   "-plugins                  Plugins to deploy (platforms,styles)"
	printf "%s\n"   "-libraries                Append libraries to deploy ()"
	printf "%s\n"   "-environment              Set system environment [MSYS]"
	printf "%s\n"   "-system                   Set system architecture [MINGW64]"
	printf "%s\n"   "-qt-version               Set Qt version [6.x.x]"
	printf "%s\n"   "-lib-path                 Set system environment lib path"
	printf "%s\n"   "-qt-path                  Set Qt path"
	printf "%s\n"   "-framework-path           Set Qt framework path"
	printf "%s\n"   "-plugins-path             Set Qt plugins path"
	printf "%s\n"   "-h --help                 Display this help and exit"
}

error () {
	local msg="$1"

	echo "$msg" >&2
}

is_msys () {
	if [[ -n "$MSYSTEM" ]]; then
		echo 1
	fi
}

is_framework () {
	local path="$1"

	if [[ "$path" =~ ".dll" && "$path" =~ "Qt" ]]; then
		echo 1
	fi
}

is_plugin () {
	local path="$1"

	if [[ "$path" =~ ".dll" && "$path" =~ "/plugins" ]]; then
		echo 1
	fi
}

path_abspath () {
	local path="$1"
	local basepath="$2"

	local abspath="$path"

	if [[ -n "$basepath" ]]; then
		path=$(basename "$path")
		abspath="${basepath}/${path}"
	fi

	echo "$abspath"
}

path_source () {
	local path="$1"

	echo $(path_abspath "$path" "")
}

path_target () {
	local path="$1"

	local basepath="$_DEST_DIR"

	echo $(path_abspath "$path" "$basepath")
}

relname () {
	local path="$1"

	local _path="$path"
	local filename=$(basename "$path")
	path="${path##$_DEST_DIR}"

	if [[ "$path" == "$filename" ]]; then
		local dirname=$(dirname "$_path")
		dirname=$(basename "$dirname")

		path="${dirname}/${filename}"
	fi

	echo "$path"
}

trim () {
	local value="$1"

	value=$(echo "$value" | xargs)

	echo "$value"
}

qt_version () {
	if [[ -n "$__QTVER" ]]; then
		echo "$__QTVER"
	fi

	local qt_ver="$_QT_VER"
	local qt_version="$_QT_VERSION"

	if [[ "${_QT_VERSION%%.*}" -ge 5 && "$_QT_VERSION" =~ [0-9]\.[0-9]+\.[0-9]+ ]]; then
		qt_ver="${_QT_VERSION%%.*}"
		qt_version="$_QT_VERSION"
	else
		local tip="Allowed values: 6.x.x 5.x.x"
		error "$(printf "Error Qt version unknown: %s\n  %s\n" "$_QT_VERSION" "$tip")"

		return 1
	fi

	__QTVER="$qt_ver"
	__QTVERSION="$qt_version"
}

lib_path () {
	if [[ -n "$_LIB_PATH" ]]; then
		echo "$_LIB_PATH"
	fi

	local lib_path

	if [[ "$_ENVIRONMENT" == "MSYS" && $(is_msys) ]]; then
		if [[ "$_SYSTEM" == "MINGW64" ]]; then
			lib_path="/mingw64"
		elif [[ "$_SYSTEM" == "MINGW32" ]]; then
			lib_path="/mingw32"
		elif [[ "$_SYSTEM" == "UCRT64" ]]; then
			lib_path="/ucrt64"
		elif [[ "$_SYSTEM" == "CLANG64" ]]; then
			lib_path="/clang64"
		elif [[ "$_SYSTEM" == "CLANG32" ]]; then
			lib_path="/clang32"
		elif [[ "$_SYSTEM" == "CLANGARM64" ]]; then
			lib_path="/clangarm64"
		fi
	else
		if [[ "$_SYSTEM" == "MINGW64" && -e "/usr/x86_64-w64-mingw32" ]]; then
			lib_path="/usr/x86_64-w64-mingw32"
		elif [[ "$_SYSTEM" == "MINGW32" && -e "/usr/i686-w64-mingw32" ]]; then
			lib_path="/usr/i686-w64-mingw32"
		fi
	fi

	if [[ -z "$lib_path" ]]; then
		local tip="You should provide lib path through -lib-path argument."
		error "$(printf "Error lib path unknown\n  %s\n" "$tip")"

		return 1
	fi

	if [[ ! -e "$lib_path" ]]; then
		error "$(printf "Error lib path not found: %s\n" "$lib_path")"

		return 1
	fi

	_LIB_PATH="$lib_path"
}

qt_path () {
	if [[ -n "$_QT_PATH" ]]; then
		echo "$_QT_PATH"
	fi

	local qt_path=$(lib_path)

	if [[ -z "$qt_path" ]]; then
		local tip="You should provide Qt path through -qt-path argument."
		error "$(printf "Error Qt path unknown\n  %s\n" "$tip")"

		return 1
	fi

	if [[ ! -e "$qt_path" ]]; then
		error "$(printf "Error Qt path not found: %s\n" "$qt_path")"

		return 1
	fi

	_QT_PATH="$qt_path"
}

framework_path () {
	if [[ -n "$_FRAMEWORK_PATH" ]]; then
		echo "$_FRAMEWORK_PATH"
	fi

	local qt_path=$(qt_path)
	local framework_path="${qt_path}/bin"

	if [[ ! -e "$framework_path" ]]; then
		error "$(printf "Error Qt framework path not found: %s\n" "$framework_path")"

		return 1
	fi

	_FRAMEWORK_PATH="$framework_path"
}

plugins_path () {
	if [[ -n "$_PLUGINS_PATH" ]]; then
		echo "$_PLUGINS_PATH"
	fi

	local qt_path=$(qt_path)
	local plugins_path

	if [[ "$_ENVIRONMENT" == "MSYS" && $(is_msys) ]]; then
		plugins_path="${qt_path}/share/qt${__QTVER}/plugins"
	else
		plugins_path="${qt_path}/lib/qt${__QTVER}/plugins"
	fi

	if [[ ! -e "$plugins_path" ]]; then
		error "$(printf "Error Qt plugins path not found: %s\n" "$plugins_path")"

		return 1
	fi

	_PLUGINS_PATH="$plugins_path"
}

recurse_dependency () {
	local path="$1"

	if [[ "$_VERBOSE" == true ]]; then
		local filename=$(basename "$path")
		printf "dependency: %s\n" "$filename"
	fi

	if [[ ! -e "$path" ]]; then
		error "$(printf "Error dependency file not found: %s\n" "$path")"

		return 1
	fi

	local srcpath=$(path_source "$path")
	local dstpath=$(path_target "$path")

	local overwrite=false

	if [[ "$_FORCE_OVERWRITE" == true || ! -e "$dstpath" ]]; then
		overwrite=true
	elif [[ "$_VERBOSE" == true ]]; then
		local srcfilename=$(basename "$srcpath")
		local dstfilename=$(relname "$dstpath")
		printf "no overwrite: %s  already at: %s\n" "$srcfilename" "$dstfilename"
	fi

	if [[ "$overwrite" == true ]]; then
		copy_dependency "$srcpath" "$dstpath"

		if [[ ! "$_VERBOSE" ]]; then
			local relpath=$(relname "$dstpath")
			echo "$relpath\n"
		fi
	fi
}

copy_dependency () {
	local srcpath="$1"
	local dstpath="$2"

	if [[ "$_VERBOSE" == true ]]; then
		local srcfilename=$(basename "$srcpath")
		local dstfilename=$(relname "$dstpath")
		printf "copy: %s  to: %s\n" "$srcfilename" "$dstfilename"
	fi

	if [[ "$_SIMULATE" == false ]]; then
		if [[ -d "$srcpath" ]]; then
			if [[ "$_FORCE_OVERWRITE" == true ]]; then
				cp -Rf "$srcpath" "$dstpath"
			elif [[ ! -e "$dstpath" ]]; then
				cp -R "$srcpath" "$dstpath"
			fi
		else
			if [[ "$_FORCE_OVERWRITE" == true ]]; then
				cp -f "$srcpath" "$dstpath"
			elif [[ ! -e "$dstpath" ]]; then
				cp "$srcpath" "$dstpath"
			fi
		fi
	elif [[ "$_VERBOSE" == true ]]; then
		local _type="file"
		if [[ -d "$srcpath" ]]; then
			_type="directory"
		fi

		printf "  copy %s from \"%s\" to \"%s\"\n" "$_type" "$srcpath" "$dstpath"
	fi
}

deploy_module () {
	local module="$1"

	local modulename="Qt${__QTVER}${module}"

	if [[ "$_VERBOSE" == true ]]; then
		printf "module: %s  as: %s\n" "$module" "$modulename"
	fi

	local basepath=$(framework_path)
	local path="${modulename}.dll"

	path="${basepath}/$path"

	if [[ ! -e "$path" ]]; then
		error "$(printf "Error module file not found: %s\n" "$path")"

		return 1
	fi

	local srcpath=$(path_source "$path")
	local dstpath=$(path_target "$path")

	local overwrite=false

	if [[ "$_FORCE_OVERWRITE" == true || ! -e "$dstpath" ]]; then
		overwrite=true
	elif [[ "$_VERBOSE" == true ]]; then
		local srcfilename=$(basename "$srcpath")
		local dstfilename=$(relname "$dstpath")
		printf "no overwrite: %s  already at: %s\n" "$srcfilename" "$dstfilename"
	fi

	if [[ "$overwrite" == true ]]; then
		copy_dependency "$srcpath" "$dstpath"

		if [[ ! "$_VERBOSE" ]]; then
			local relpath=$(relname "$dstpath")
			echo "$relpath\n"
		fi
	fi

	local deps=()

	if [[ "$module" == "Core" ]]; then
		if [[ "$_SYSTEM" == "MINGW64" || "$_SYSTEM" == "UCRT64" ]]; then
			deps=("libgcc_s_seh-1")
		elif [[ "$_SYSTEM" == "MINGW32" ]]; then
			deps=("libgcc_s_dw2-1")
		fi
		if [[ "$_SYSTEM" == "MINGW64" || "$_SYSTEM" == "MINGW32" || "$_SYSTEM" == "UCRT64" ]]; then
			deps+=("libstdc++-6" "libwinpthread-1")
		elif [[ "$_SYSTEM" == "CLANG64" || "$_SYSTEM" == "CLANG32" || "$_SYSTEM" == "CLANGARM64" ]]; then
			deps+=("libc++" "libunwind")
		fi
		if [[ "$_ENVIRONMENT" == "MSYS" && $(is_msys) ]]; then
			local semmp="${__QTVERSION#*.}"

			deps+=("libdouble-conversion")
			if [[ "${__QTVERSION%%.*}" -eq 6 && "${semmp%%.*}" -gt 7 || ("${semmp%%.*}" -eq 7 && "${semmp##*.}" -ge 2) ]]; then
				deps+=("libicuin75" "libicuuc75" "libicudt75")
			elif [[ "${__QTVERSION%%.*}" -eq 5 && "${semmp%%.*}" -gt 15 || ("${semmp%%.*}" -eq 15 && "${semmp##*.}" -ge 14) ]]; then
				deps+=("libicuin75" "libicuuc75" "libicudt75")
			else
				deps+=("libicuin74" "libicuuc74" "libicudt74")
			fi
			if [[ "$__QTVER" -eq 6 ]]; then
				deps+=("libb2-1")
			fi
		else
			deps+=("libssp-0")
		fi
		deps+=(
			"libpcre2-16-0"
			"libzstd"
			"zlib1"
		)
	elif [[ "$module" == "Gui" ]]; then
		deps=(
			"libbrotlicommon"
			"libbrotlidec"
			"libbz2-1"
			"libfreetype-6"
			"libglib-2.0-0"
			"libgraphite2"
			"libharfbuzz-0"
			"libiconv-2"
			"libintl-8"
			"libjpeg-8"
			"libpcre2-8-0"
			"libpng16-16"
		)
		if [[ "$_ENVIRONMENT" == "MSYS" && $(is_msys) ]]; then
			deps+=("libmd4c")
		fi
		# requires: Core
	elif [[ "$module" == "Widgets" ]]; then
		deps=()
		# requires: Core,Gui
	elif [[ "$module" == "PrintSupport" ]]; then
		deps=()
		# requires: Core,Gui,Widgets
	fi

	for dep in "${deps[@]}"; do
		local basepath=$(lib_path)
		local path="${dep}.dll"

		path="${basepath}/bin/$path"

		recurse_dependency "$path"
	done
}

deploy_plugin () {
	local plugin="$1"

	if [[ "$_VERBOSE" == true ]]; then
		printf "plugin: %s\n" "$plugin"
	fi

	local basepath=$(plugins_path)
	local path="${basepath}/$plugin"

	if [[ ! -e "$path" ]]; then
		error "$(printf "Error plug-in directory not found: %s\n" "$path")"

		return 1
	fi

	local srcpath=$(path_source "$path")
	local dstpath=$(path_target "$path")

	local overwrite=false

	if [[ "$_FORCE_OVERWRITE" == true || ! -e "$dstpath" ]]; then
		overwrite=true
	elif [[ "$_VERBOSE" == true ]]; then
		local srcfilename=$(basename "$srcpath")
		local dstfilename=$(relname "$dstpath")
		printf "no overwrite: %s  already at: %s\n" "$srcfilename" "$dstfilename"
	fi

	if [[ "$overwrite" == true ]]; then
		copy_dependency "$srcpath" "$dstpath"

		if [[ ! "$_VERBOSE" ]]; then
			local run=$(ls -1 "$srcpath")

			if [[ -z "$run" ]]; then
				return 0
			fi

			IFS=$'\n'
			local files=$run

			for filename in $run; do
				filename=$(trim "$filename")
				local path="${_DEST_DIR}/${filename}"

				local relpath=$(relname "$path")
				echo "$relpath\n"
			done
		fi
	fi

	local deps=()

	for dep in "${deps[@]}"; do
		local basepath=$(lib_path)
		local path="${dep}.dll"

		path="${basepath}/bin/$path"

		recurse_dependency "$path"
	done
}

deploy_library () {
	local library="$1"

	if [[ "$_VERBOSE" == true ]]; then
		local libname=$(basename "$library")
		libname="${libname##.dll*}"
		printf "append library: %s\n" "$libname"
	fi

	local basepath
	local path

	if [[ "$library" =~ "/" ]]; then
		basepath=$(dirname "$library")
		path="$library"
	else
		basepath=$(lib_path)
		path="${basepath}/bin/$library"
	fi

	if [[ ! -e "$path" ]]; then
		error "$(printf "Error library file not found: %s\n" "$path")"

		return 1
	fi

	local srcpath=$(path_source "$path")
	local dstpath=$(path_target "$path")

	local overwrite=false

	if [[ "$_FORCE_OVERWRITE" == true || ! -e "$dstpath" ]]; then
		overwrite=true
	elif [[ "$_VERBOSE" == true ]]; then
		local srcfilename=$(basename "$srcpath")
		local dstfilename=$(relname "$dstpath")
		printf "no overwrite: %s  already at: %s\n" "$srcfilename" "$dstfilename"
	fi

	if [[ "$overwrite" == true ]]; then
		copy_dependency "$srcpath" "$dstpath"

		if [[ ! "$_VERBOSE" ]]; then
			local relpath=$(relname "$dstpath")
			echo "$relpath\n"
		fi
	fi
}

deploy () {
	local input_file="$_INPUT_FILE"

	if [[ ! -e "$input_file" ]]; then
		error "$(printf "Error input file not found: %s\n" "$input_file")"

		return 1
	fi

	if [[ "$_VERBOSE" == true ]]; then
		printf "executable: %s\n" "$input_file"
	fi

	local dest_dir

	if [[ -n "$_DEST_DIR" ]]; then
		dest_dir="$_DEST_DIR"

		if [[ ! -e "$dest_dir" ]]; then
			error "$(printf "Error destination path not found: %s\n" "$dest_dir")"

			return 1
		elif [[ ! -d "$dest_dir" ]]; then
			error "$(printf "Error destination path is not directory: %s\n" "$dest_dir")"

			return 1
		fi

		printf "base: %s\n" "$dest_dir"
	else
		dest_dir=$(dirname "$input_file")
		_DEST_DIR="$dest_dir"
	fi

	if [[ "$_SYSTEM" == "MSVC" ]]; then
		local tip="You should put Visual C++ Redistributable runtime along the distributable directory."
		printf "system: %s\n  %s\n" "$_SYSTEM" "$tip"
	else
		printf "system: %s\n" "$_SYSTEM"
	fi

	if [[
		"$_SYSTEM" != "MINGW64" &&
		"$_SYSTEM" != "MINGW32" &&
		"$_SYSTEM" != "UCRT64" &&
		"$_SYSTEM" != "CLANG64" &&
		"$_SYSTEM" != "CLANG32" &&
		"$_SYSTEM" != "CLANGARM64" &&
		"$_SYSTEM" != "MSVC"
	]]
	then
		local tip="Allowed values: MINGW64 MINGW32 UCRT64 CLANG64 CLANG32 CLANGARM64 MSVC"
		error "$(printf "Error system value not valid: %s\n  %s\n" "$_SYSTEM" "$tip")"

		return 1
	fi

	qt_version
	lib_path
	qt_path
	framework_path
	plugins_path

	mkdir -p "${dest_dir}"

	local modules=()

	if [[ "${_MODULES[*]}" =~ "Core" ]]; then
		modules=("${_MODULES[@]}")
	else
		modules+=("Core")
		modules+=("${_MODULES[@]}")
	fi

	for module in "${modules[@]}"; do
		module=$(trim "$module")

		deploy_module "$module"
	done

	if [[ "$_DEPLOY_PLUGINS" == true ]]; then
		local plugins=("${_PLUGINS[@]}")

		for plugin in "${plugins[@]}"; do
			plugin=$(trim "$plugin")

			deploy_plugin "$plugin"
		done
	fi

	local libraries=("${_APPEND_LIBS[@]}")

	for library in "${libraries[@]}"; do
		library=$(trim "$library")

		deploy_library "$library"
	done
}


if [[ -z "$@" ]]; then
	usage

	exit 0
fi

_INPUT_FILE="$1"

for SRG in "$@"; do
	case "$SRG" in
		--verbose)
			_VERBOSE=true
			shift
			;;
		-s|--simulate)
			_SIMULATE=true
			shift
			;;
		-f|--force)
			_FORCE_OVERWRITE=true
			shift
			;;
		-o*|--dest-path*)
			_DEST_DIR="$2"
			shift
			shift
			;;
		-environment*)
			_ENVIRONMENT="$2"
			shift
			shift
			;;
		-system*)
			_SYSTEM="$2"
			shift
			shift
			;;
		-qt-version*)
			_QT_VERSION="$2"
			shift
			shift
			;;
		-modules*)
			_MODULES=(${2//,/ })
			shift
			shift
			;;
		-plugins*)
			_PLUGINS=(${2//,/ })
			shift
			shift
			;;
		-libraries*)
			_APPEND_LIBS=(${2//,/ })
			shift
			shift
			;;
		-lib-path*)
			_LIB_PATH="$2"
			shift
			shift
			;;
		-qt-path*)
			_QT_PATH="$2"
			shift
			shift
			;;
		-framework-path*)
			_FRAMEWORK_PATH="$2"
			shift
			shift
			;;
		-plugins-path*)
			_PLUGINS_PATH="$2"
			shift
			shift
			;;
		-np|--no-deploy-plugins)
			_DEPLOY_PLUGINS=false
			shift
			;;
		-h|--help)
			usage

			exit 0
			;;
		-*)
			printf "%s: %s %s\n\n" "$0" "Illegal option" "$1"

			usage 1

			exit 1
			;;
		*)
			[[ "$1" != "-"* ]] && shift
			;;
	esac
done

deploy

