LOAD_ENV := . dots/.env/*.env &&

.PHONY: install
install:
	./scripts/install.sh

.PHONY: clean/backups
clean:
	rm -rf ./backup

.PHONY: brew/install
brew/install:
	$(LOAD_ENV) brew bundle --file=./dots/.homebrew/Brewfile

.PHONY: brew/install/%
brew/install/%:
	$(LOAD_ENV) brew bundle --file=./dots/.homebrew/Brewfile.$*

PERMGEN := cd tools/permgen && go run . -config permissions.yaml -claude ../../modules/dots/claude/settings.pinned.json

.PHONY: perms/generate
perms/generate:
	$(PERMGEN)

.PHONY: perms/check
perms/check:
	$(PERMGEN) -check
