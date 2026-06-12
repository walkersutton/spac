#!/usr/bin/env zsh
set -euo pipefail

usage() {
	printf '%s\n' "Usage: scripts/release.sh patch|minor|major|VERSION [--no-push] [--dry-run]"
	printf '%s\n' ""
	printf '%s\n' "Examples:"
	printf '%s\n' "  scripts/release.sh patch"
	printf '%s\n' "  scripts/release.sh minor"
	printf '%s\n' "  scripts/release.sh 1.2.3"
}

if [[ $# -lt 1 ]]; then
	usage >&2
	exit 1
fi

release_spec="$1"
shift

should_push=true
dry_run=false

while [[ $# -gt 0 ]]; do
	case "$1" in
		--no-push)
			should_push=false
			shift
			;;
		--dry-run)
			dry_run=true
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

if [[ -n "$(git status --porcelain)" && "$dry_run" == false ]]; then
	printf '%s\n' "Working tree must be clean before releasing. Commit or stash your changes first." >&2
	exit 1
fi

if [[ "$dry_run" == false ]]; then
	git fetch --tags origin
fi

read -r current_version current_build <<< "$(scripts/bump-version.sh --plain)"

normalize_version() {
	local raw="$1"
	local parts=("${(@s:.:)raw}")
	printf '%s.%s.%s\n' "${parts[1]:-0}" "${parts[2]:-0}" "${parts[3]:-0}"
}

version_build_number() {
	local raw="$1"
	local parts=("${(@s:.:)raw}")
	local major="${parts[1]:-0}"
	local minor="${parts[2]:-0}"
	local patch="${parts[3]:-0}"
	printf '%s\n' "$((major * 10000 + minor * 100 + patch))"
}

version_greater_than() {
	local left="$1"
	local right="$2"
	local left_parts=("${(@s:.:)left}")
	local right_parts=("${(@s:.:)right}")

	for index in 1 2 3; do
		local left_number="${left_parts[$index]:-0}"
		local right_number="${right_parts[$index]:-0}"
		if (( left_number > right_number )); then
			return 0
		fi
		if (( left_number < right_number )); then
			return 1
		fi
	done

	return 1
}

base_version="$(normalize_version "$current_version")"

for tag_name in ${(f)"$(git tag --list 'v[0-9]*.[0-9]*.[0-9]*')"}; do
	tag_version="${tag_name#v}"
	if [[ "$tag_version" =~ '^[0-9]+\.[0-9]+\.[0-9]+$' ]] && version_greater_than "$tag_version" "$base_version"; then
		base_version="$tag_version"
	fi
done

version_parts=("${(@s:.:)base_version}")
major="${version_parts[1]:-0}"
minor="${version_parts[2]:-0}"
patch="${version_parts[3]:-0}"

if [[ ! "$major" =~ '^[0-9]+$' || ! "$minor" =~ '^[0-9]+$' || ! "$patch" =~ '^[0-9]+$' ]]; then
	printf 'Current version must be numeric, got: %s\n' "$current_version" >&2
	exit 1
fi

case "$release_spec" in
	patch)
		next_version="$major.$minor.$((patch + 1))"
		;;
	minor)
		next_version="$major.$((minor + 1)).0"
		;;
	major)
		next_version="$((major + 1)).0.0"
		;;
	*)
		next_version="$release_spec"
		;;
esac

if [[ ! "$next_version" =~ '^[0-9]+\.[0-9]+\.[0-9]+$' ]]; then
	printf 'Release version must use MAJOR.MINOR.PATCH, got: %s\n' "$next_version" >&2
	exit 1
fi

if [[ ! "$current_build" =~ '^[0-9]+$' ]]; then
	printf 'Current build number must be an integer, got: %s\n' "$current_build" >&2
	exit 1
fi

version_build="$(version_build_number "$next_version")"
next_build="$((current_build + 1))"
if (( version_build > next_build )); then
	next_build="$version_build"
fi
tag="v$next_version"
branch="$(git branch --show-current)"

if git rev-parse "$tag" >/dev/null 2>&1; then
	printf 'Tag already exists locally: %s\n' "$tag" >&2
	exit 1
fi

if [[ "$dry_run" == true ]]; then
	printf 'Would release %s (%s) from %s (%s)\n' "$next_version" "$next_build" "$current_version" "$current_build"
	printf 'Would create commit: Release %s\n' "$tag"
	printf 'Would create tag: %s\n' "$tag"
	if [[ "$should_push" == true ]]; then
		printf 'Would push branch %s and tag %s to origin\n' "$branch" "$tag"
	fi
	exit 0
fi

scripts/bump-version.sh --version "$next_version" --build "$next_build"

xcodebuild -scheme spac \
	-configuration Release \
	-derivedDataPath build

git add spac.xcodeproj/project.pbxproj
git commit -m "Release $tag"
git tag "$tag"

if [[ "$should_push" == true ]]; then
	git push origin "$branch" "$tag"
else
	printf 'Created %s locally. Push with: git push origin %s %s\n' "$tag" "$branch" "$tag"
fi
