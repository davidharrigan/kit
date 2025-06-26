.PHONY: install
install:
	./install.sh

.PHONY: clean/backups
clean:
	rm -rf ./backup

galaxy/install:
	ansible-galaxy install -r ./ansible/requirements.yaml

playbook/personal:
	ansible-playbook ./ansible/macos.yaml -l personal

playbook/work:
	ansible-playbook ./ansible/macos.yaml -l work
