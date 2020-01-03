
.PHONY: install/dots
install/dots:
	@./install/install-dots.sh

.PHONY: backup
backup:
	@./install/backup.sh

.PHONY: clean/backups
clean/backups:
	@./install/clean-backups.sh

