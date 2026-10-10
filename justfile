# Flake host to build: the lowercased LocalHostName, which matches hosts/<name>.nix.
# Override with `just host=power build` or KIT_HOST=power.
host := env("KIT_HOST", `scutil --get LocalHostName | tr '[:upper:]' '[:lower:]'`)

# darwin-rebuild isn't on PATH until the first apply, so run it straight from nix-darwin.
rebuild := `command -v darwin-rebuild || echo "nix run github:nix-darwin/nix-darwin/nix-darwin-26.05#darwin-rebuild --"`

# Build the system without activating it.
build:
    {{rebuild}} build --flake .#{{host}}

# Build, then list package changes against the running system.
diff: build
    nix store diff-closures /run/current-system ./result

# Build, then activate.
apply: build
    sudo {{rebuild}} switch --flake .#{{host}}

# Bump all flake inputs (flake.lock).
update:
    nix flake update

check:
    nix flake check

# Snapshot the current machine state into baseline/.
capture:
    ./baseline/capture.sh

# Setup after the first apply: Oh My Zsh, the agent user's password, Screen
# Sharing and FileVault, then credentials. -i also offers to redo done steps.
bootstrap *args: && (credentials args)
    ./scripts/bootstrap.sh {{args}}

# gh sign-in, GitHub SSH keys and the agent's 1Password service account.
credentials *args:
    ./scripts/credentials.sh {{args}}

rollback:
    sudo darwin-rebuild --rollback

generations:
    darwin-rebuild --list-generations

# Forward power's Hermes backend to localhost:9119 for Hermes Desktop. Ctrl-C to stop.
hermes-tunnel:
    ssh -N -L 9119:127.0.0.1:9119 agent@power.lan
