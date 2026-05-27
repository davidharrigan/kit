LOAD_ENV := . dots/.env/*.env &&

.PHONY: install
install:
	./install.sh

.PHONY: clean/backups
clean:
	rm -rf ./backup

.PHONY: brew/install
brew/install:
	$(LOAD_ENV) brew bundle --file=./dots/.homebrew/Brewfile

.PHONY: brew/install/%
brew/install/%:
	$(LOAD_ENV) brew bundle --file=./dots/.homebrew/Brewfile.$*

galaxy/install:
	ansible-galaxy install -r ./ansible/requirements.yaml

playbook/personal:
	ansible-playbook ./ansible/macos.yaml -l personal

playbook/work:
	ansible-playbook ./ansible/macos.yaml -l work
