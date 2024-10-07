.PHONY: install/dots
install/dots:
	bash ./install/install-dots.sh

.PHONY: backup/dots
backup/dots:
	@./install/backup.sh

.PHONY: clean/backups
clean/backups:
	@./install/clean-backups.sh

galaxy/install:
	ansible-galaxy install -r ./ansible/requirements.yaml

playbook/personal:
	ansible-playbook ./ansible/macos.yaml -l personal
