.PHONY: preview release-patch release-minor release-major

preview:
	scripts/preview.sh

release-patch:
	scripts/release.sh patch

release-minor:
	scripts/release.sh minor

release-major:
	scripts/release.sh major
