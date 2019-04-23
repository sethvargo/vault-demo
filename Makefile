demo:
	osascript demo.scpt

vault:
	vault server --dev

postgres:
	./scripts/start-postgres.sh

cred:
	vault read database/creds/readonly

secure:
	vault lease revoke -prefix database/

1_configure_vault:
	-less scripts/configure-vault.sh
	-scripts/configure-vault.sh

2_create_users:
	-less scripts/create-users.sh
	-scripts/create-users.sh

3_generate_credentials:
