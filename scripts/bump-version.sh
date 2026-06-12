#!/usr/bin/env zsh
set -euo pipefail

project_file="spac.xcodeproj/project.pbxproj"

usage() {
	printf '%s\n' "Usage: scripts/bump-version.sh [--version VERSION] [--build BUILD] [--bump-build] [--print] [--plain]"
	printf '%s\n' ""
	printf '%s\n' "Examples:"
	printf '%s\n' "  scripts/bump-version.sh"
	printf '%s\n' "  scripts/bump-version.sh --version 1.0.1"
	printf '%s\n' "  scripts/bump-version.sh --version 1.1 --build 12"
	printf '%s\n' "  scripts/bump-version.sh --print"
}

current_version="$(sed -n 's/^[[:space:]]*MARKETING_VERSION = \([^;]*\);$/\1/p' "$project_file" | head -n 1)"
current_build="$(sed -n 's/^[[:space:]]*CURRENT_PROJECT_VERSION = \([^;]*\);$/\1/p' "$project_file" | head -n 1)"

if [[ -z "$current_version" || -z "$current_build" ]]; then
	printf '%s\n' "Could not read MARKETING_VERSION and CURRENT_PROJECT_VERSION from $project_file" >&2
	exit 1
fi

new_version="$current_version"
new_build="$current_build"
build_was_set=false
should_bump_build=false
print_only=false
plain_print=false

if [[ $# -eq 0 ]]; then
	should_bump_build=true
fi

while [[ $# -gt 0 ]]; do
	case "$1" in
		--version)
			if [[ $# -lt 2 ]]; then
				printf '%s\n' "--version requires a value" >&2
				exit 1
			fi
			new_version="$2"
			should_bump_build=true
			shift 2
			;;
		--build)
			if [[ $# -lt 2 ]]; then
				printf '%s\n' "--build requires a value" >&2
				exit 1
			fi
			new_build="$2"
			build_was_set=true
			shift 2
			;;
		--bump-build)
			should_bump_build=true
			shift
			;;
		--print)
			print_only=true
			shift
			;;
		--plain)
			plain_print=true
			shift
			;;
		-h|--help)
			usage
			exit 0
			;;
		*)
			printf 'Unknown option: %s\n' "$1" >&2
			usage >&2
			exit 1
			;;
	esac
done

if [[ "${plain_print:-false}" == true ]]; then
	printf '%s %s\n' "$current_version" "$current_build"
	exit 0
fi

if [[ "$print_only" == true ]]; then
	printf 'Version %s (%s)\n' "$current_version" "$current_build"
	exit 0
fi

if [[ ! "$current_build" =~ '^[0-9]+$' ]]; then
	printf 'Current build number is not an integer: %s\n' "$current_build" >&2
	exit 1
fi

if [[ "$build_was_set" == false && "$should_bump_build" == true ]]; then
	new_build="$((current_build + 1))"
fi

if [[ ! "$new_build" =~ '^[0-9]+$' ]]; then
	printf 'Build number must be an integer: %s\n' "$new_build" >&2
	exit 1
fi

NEW_VERSION="$new_version" NEW_BUILD="$new_build" /usr/bin/perl -0pi -e '
	s/(MARKETING_VERSION = )[^;]+(;)/$1$ENV{NEW_VERSION}$2/g;
	s/(CURRENT_PROJECT_VERSION = )[^;]+(;)/$1$ENV{NEW_BUILD}$2/g;
' "$project_file"

printf 'Updated version: %s (%s) -> %s (%s)\n' "$current_version" "$current_build" "$new_version" "$new_build"
