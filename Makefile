

.PHONY: backup
backup:
	@./install/backup.sh

.PHONY: clean/backups
clean/backups:
	@./install/clean-backups.sh

