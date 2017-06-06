lint:
	@echo "--> Running swiftlint"
	swiftlint

test:
	@echo "--> Running all tests"
	fastlane test

build-carthage:
	@echo "--> Creating Sentry framework package with carthage"
	cd KSCrash && carthage build --no-skip-current --cache-builds
	cd KSCrash && carthage archive Sentry --output Sentry.framework.zip

release: bump-version git-commit-add

pod-lint:
	@echo "--> Build local pod"
	pod lib lint --allow-warnings

build-version-bump:
	@echo "--> Building VersionBump"
	cd Utils/VersionBump && swift build

bump-version: build-version-bump
	@echo "--> Bumping version from ${FROM} to ${TO}"
	./Utils/VersionBump/.build/debug/VersionBump ${FROM} ${TO}

clean-version-bump:
	@echo "--> Clean VersionBump"
	cd Utils/VersionBump && rm -rf .build && swift build

git-commit-add:
	@echo "\n\n\n--> Commting git ${TO}"
	git commit -am "Bump version to ${TO}"
	git tag ${TO}
	git push
	git push --tags
