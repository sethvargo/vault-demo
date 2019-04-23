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
	-scripts/configure-vault.sh

2_create_users:
	-scripts/create-users.sh

3_generate_credentials:
	-scripts/generate-credentials.sh
