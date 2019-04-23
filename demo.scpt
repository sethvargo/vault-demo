# AppleScript for Demo Window layout
# execute with `osascript window_layout.scpt`

tell application "iTerm"
	activate
	tell current window
		create tab with default profile
	end tell
	set pane_1 to (current session of current window)

	tell pane_1
		set pane_3 to (split horizontally with same profile)
	end tell

	tell pane_1
		set pane_2 to (split vertically with same profile)
	end tell

	tell pane_1
		write text "cd ~/Projects/vault-demo"
		write text "export VAULT_DEV_ROOT_TOKEN_ID=root"
		write text "export VAULT_ADDR=http://127.0.0.1:8200"
		write text "vault server --dev"
	end tell

	tell pane_2
		write text "cd ~/Projects/vault-demo"
		write text "./scripts/start-postgres.sh"
		write text "export VAULT_DEV_ROOT_TOKEN_ID=root"
		write text "export VAULT_ADDR=http://127.0.0.1:8200"
		write text "docker exec -ti vault-demo-postgres psql -U postgres"
	end tell

	tell pane_3
		write text "cd ~/Projects/vault-demo"
		write text "export VAULT_DEV_ROOT_TOKEN_ID=root"
		write text "export VAULT_ADDR=http://127.0.0.1:8200"
		write text "sleep 10s"
		write text "vault login root"
		write text "open http://127.0.0.1:8200"
		write text "open http://gitpitch.com/kecorbin/vault-demo/gitpitch"
	end tell

end tell
