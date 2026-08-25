.PHONY: build bundle run install dmg cask clean

build:
	swift build

bundle: build
	./scripts/bundle.sh

run: bundle
	open ./Terminote.app

install: bundle
	sudo ditto ./Terminote.app /Applications/Terminote.app

dmg:
	./scripts/dmg.sh

cask: dmg
	./scripts/cask.sh

clean:
	swift package clean
	rm -rf ./Terminote.app ./dist
