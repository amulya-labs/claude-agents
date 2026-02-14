#!/bin/bash
# Claude Code PreToolUse hook for Bash command validation
# Strips env var prefixes and validates the actual command against allow/deny patterns

set -e

# Read JSON input from stdin
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Exit early if no command
[[ -z "$COMMAND" ]] && exit 0

# Strip environment variable assignments from the beginning of the command
# Handles: VAR=val, VAR="val", VAR='val', VAR=$(cmd), VAR=`cmd`, VAR=$VAR
strip_env_vars() {
    local cmd="$1"

    while true; do
        # Remove leading whitespace
        cmd="${cmd#"${cmd%%[![:space:]]*}"}"

        # Pattern: VAR=value (unquoted, no spaces in value)
        # Pattern: VAR="value" or VAR='value' (quoted)
        # Pattern: VAR=$(command) or VAR=`command` (command substitution)
        # Pattern: VAR=$OTHER_VAR
        if [[ "$cmd" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then
            # Extract variable name
            local varname="${cmd%%=*}"
            local rest="${cmd#*=}"

            # Handle different value formats
            if [[ "$rest" =~ ^\$\( ]]; then
                # Command substitution $(...)
                local depth=1
                local i=2
                while (( depth > 0 && i < ${#rest} )); do
                    case "${rest:$i:1}" in
                        '(') ((depth++)) ;;
                        ')') ((depth--)) ;;
                    esac
                    ((i++))
                done
                cmd="${rest:$i}"
            elif [[ "$rest" =~ ^\` ]]; then
                # Backtick command substitution `...`
                rest="${rest:1}"
                cmd="${rest#*\`}"
            elif [[ "$rest" =~ ^\" ]]; then
                # Double-quoted value
                rest="${rest:1}"
                # Handle escaped quotes
                while [[ "$rest" =~ ^[^\"]*\\\" ]]; do
                    rest="${rest#*\\\"}"
                done
                cmd="${rest#*\"}"
            elif [[ "$rest" =~ ^\' ]]; then
                # Single-quoted value
                rest="${rest:1}"
                cmd="${rest#*\'}"
            elif [[ "$rest" =~ ^\$[A-Za-z_][A-Za-z0-9_]* ]]; then
                # Variable reference $VAR
                cmd="${rest#\$}"
                cmd="${cmd#[A-Za-z_]*}"
                cmd="${cmd#[A-Za-z0-9_]*}"
            else
                # Unquoted value - ends at whitespace
                cmd="${rest#*[[:space:]]}"
                [[ "$cmd" == "$rest" ]] && cmd=""
            fi
        else
            break
        fi
    done

    # Remove leading whitespace again
    echo "${cmd#"${cmd%%[![:space:]]*}"}"
}

# Get the actual command without env var prefixes
ACTUAL_CMD=$(strip_env_vars "$COMMAND")

# If stripping removed everything, use original
[[ -z "$ACTUAL_CMD" ]] && ACTUAL_CMD="$COMMAND"

# === DENY PATTERNS (checked first - blocks even if allowed) ===
DENY_PATTERNS=(
    # Privilege escalation
    "^sudo "
    "^su "
    "^doas "

    # Destructive file operations
    "^rm -rf /$"
    "^rm -rf /\*"
    "^rm -rf ~"
    "^rm -rf \.$"
    "^rm -rf \*$"
    "^chmod 777 "
    "^chmod -R 777 "
    "^chown "
    "^chgrp "

    # Dangerous git operations
    "^git push --force"
    "^git push -f "
    "^git reset --hard"
    "^git clean -fd"

    # GitHub destructive
    "^gh pr merge"
    "^gh repo delete"

    # Docker destructive
    "^docker system prune"
    "^docker volume prune"
    "^docker network prune"
    "^docker image prune"
    "^docker rmi -f"
    "^docker rm -f"
    "^docker stop "
    "^docker kill "

    # Kubernetes mutations
    "^kubectl apply"
    "^kubectl create"
    "^kubectl delete"
    "^kubectl edit"
    "^kubectl patch"
    "^kubectl replace"
    "^kubectl scale"
    "^kubectl rollout restart"
    "^kubectl rollout undo"
    "^kubectl set "
    "^kubectl label"
    "^kubectl annotate"
    "^kubectl taint"
    "^kubectl cordon"
    "^kubectl uncordon"
    "^kubectl drain"
    "^kubectl exec"
    "^k3s kubectl apply"
    "^k3s kubectl create"
    "^k3s kubectl delete"
    "^k3s kubectl edit"
    "^k3s kubectl patch"
    "^k3s kubectl exec"

    # Helm mutations
    "^helm install"
    "^helm upgrade"
    "^helm uninstall"
    "^helm rollback"
    "^helm repo add"
    "^helm repo remove"
    "^helm repo update"
    "^helmfile apply"
    "^helmfile sync"
    "^helmfile destroy"

    # IaC mutations
    "^terraform apply"
    "^terraform destroy"
    "^terraform import"
    "^terraform taint"
    "^terraform untaint"
    "^pulumi up"
    "^pulumi destroy"
    "^pulumi refresh"
    "^ansible-playbook"

    # Cloud destructive
    "aws .* delete"
    "aws .* remove"
    "aws .* terminate"
    "gcloud .* delete"
    "az .* delete"

    # Process/system control
    "^kill -9"
    "^killall "
    "^pkill -9"
    "^reboot"
    "^shutdown"
    "^poweroff"
    "^halt"
    "^init 0"
    "^init 6"

    # Service management
    "^systemctl start"
    "^systemctl stop"
    "^systemctl restart"
    "^systemctl enable"
    "^systemctl disable"
    "^systemctl mask"
    "^service .* start"
    "^service .* stop"
    "^service .* restart"

    # Disk/partition
    "^dd "
    "^mkfs"
    "^fdisk"
    "^parted"

    # Firewall
    "^iptables"
    "^ip6tables"
    "^ufw "
    "^firewall-cmd"
    "^nft "

    # User/cron management
    "^crontab -r"
    "^crontab -e"
    "^visudo"
    "^passwd"
    "^useradd"
    "^userdel"
    "^usermod"
    "^groupadd"
    "^groupdel"

    # Secrets encryption (allow decrypt only)
    "^sops -e"
    "^sops --encrypt"

    # Remote access
    "^ssh "
    "^scp "
    "^rsync "
    "^sftp "
    "^ftp "
    "^telnet "
    "^nc -l"
)

# === ALLOW PATTERNS (auto-approve if matched and not denied) ===
ALLOW_PATTERNS=(
    # JavaScript/Node ecosystem
    "^npm "
    "^npx "
    "^node "
    "^yarn "
    "^pnpm "
    "^bun "
    "^deno "

    # Git & GitHub
    "^git "
    "^gh "

    # Python ecosystem
    "^python"
    "^pytest"
    "^poetry "
    "^pip"
    "^pipx "
    "^uv "
    "^pdm "
    "^hatch "

    # Go
    "^go "
    "^gofmt"
    "^goimports"
    "^golangci-lint"

    # Rust
    "^cargo "
    "^rustc"
    "^rustfmt"
    "^clippy"

    # Java/JVM
    "^java "
    "^javac"
    "^mvn "
    "^gradle"
    "^\./gradlew"
    "^scala"
    "^sbt "
    "^kotlin"

    # Ruby
    "^ruby "
    "^gem "
    "^bundle"
    "^rake "
    "^rails "
    "^rspec"
    "^rubocop"

    # PHP
    "^php "
    "^composer"
    "^phpunit"
    "^phpstan"

    # Other languages
    "^dotnet"
    "^elixir"
    "^mix "
    "^iex"
    "^swift"
    "^zig "
    "^lua "
    "^luarocks"
    "^perl "

    # Build tools
    "^make"
    "^cmake"
    "^ninja"
    "^meson"
    "^bazel"

    # Linters & formatters
    "^ruff "
    "^mypy"
    "^black "
    "^isort"
    "^flake8"
    "^pylint"
    "^bandit"
    "^yamllint"
    "^shellcheck"
    "^actionlint"
    "^prettier"
    "^eslint"
    "^biome"
    "^tsc"

    # Testing
    "^jest"
    "^vitest"
    "^mocha"
    "^playwright"
    "^cypress"

    # Databases (read operations)
    "^psql"
    "^mysql"
    "^sqlite3"
    "^mongosh"
    "^redis-cli"

    # Cloud CLIs (read operations validated by deny list)
    "^aws "
    "^gcloud "
    "^az "
    "^terraform "
    "^pulumi "
    "^ansible "
    "^vagrant"
    "^packer"

    # File operations
    "^ls"
    "^cat "
    "^head "
    "^tail "
    "^wc "
    "^grep"
    "^rg "
    "^ag "
    "^fd "
    "^fzf"
    "^find "
    "^pwd$"
    "^env$"
    "^printenv"
    "^which "
    "^whereis"
    "^type "
    "^file "
    "^stat "
    "^tree"
    "^cloc"
    "^tokei"
    "^mkdir"
    "^rmdir"
    "^cp "
    "^mv "
    "^ln "
    "^chmod "
    "^touch "
    "^echo "
    "^printf"
    "^sort"
    "^uniq"
    "^cut "
    "^tr "
    "^xargs"
    "^tar "
    "^zip"
    "^unzip"
    "^gzip"
    "^gunzip"
    "^zcat"
    "^du "
    "^df"
    "^free"
    "^test "
    "^\[ "
    "^tee "
    "^awk"
    "^sed "
    "^jq"
    "^yq"
    "^curl"
    "^wget"
    "^http "
    "^httpie"

    # Process inspection
    "^lsof"
    "^pgrep"
    "^pkill "
    "^ps "
    "^top"
    "^htop"
    "^timeout "
    "^time "
    "^date"
    "^cal"
    "^uptime"
    "^uname"
    "^hostname"
    "^whoami"
    "^id"
    "^groups"

    # Diff & patch
    "^diff"
    "^colordiff"
    "^delta"
    "^patch"

    # Checksums & encoding
    "^md5sum"
    "^sha256sum"
    "^sha1sum"
    "^base64"
    "^xxd"
    "^hexdump"
    "^openssl"
    "^ssh-keygen"

    # Network diagnostics
    "^dig "
    "^nslookup"
    "^host "
    "^ping"
    "^traceroute"
    "^mtr"
    "^ss "
    "^netstat"
    "^ip "
    "^ifconfig"
    "^nc "

    # Docker (read + build operations)
    "^docker "
    "^docker-compose"
    "^podman"

    # Kubernetes (read operations - mutations blocked by deny)
    "^kubectl "
    "^k3s kubectl"
    "^k9s"
    "^helm "
    "^helmfile "
    "^kustomize"
    "^skaffold"
    "^istioctl"
    "^argocd"
    "^flux"

    # Secrets (decrypt only)
    "^sops -d"
    "^sops --decrypt"
    "^age "

    # Version managers
    "^nvm "
    "^pyenv"
    "^rbenv"
    "^asdf"
    "^volta"
    "^fnm"
    "^direnv"

    # Venv binaries
    "^\.venv/bin/"
    "^venv/bin/"

    # System inspection (read-only)
    "^tailscale"
    "^mount$"
    "^dmesg"
    "^journalctl"
    "^systemctl status"
    "^systemctl show"
    "^systemctl list"
    "^systemctl is-"
    "^service .* status"

    # Common command wrappers
    "^command -v"
    "^env "
    "^exec "
    "^nohup "
    "^nice "
    "^ionice "
)

# Check deny patterns first
for pattern in "${DENY_PATTERNS[@]}"; do
    if echo "$ACTUAL_CMD" | grep -qE "$pattern"; then
        jq -n --arg reason "Blocked: matches deny pattern '$pattern'" '{
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": $reason
            }
        }'
        exit 0
    fi
done

# Check allow patterns
for pattern in "${ALLOW_PATTERNS[@]}"; do
    if echo "$ACTUAL_CMD" | grep -qE "$pattern"; then
        # Allowed - exit with success (no output = allow)
        exit 0
    fi
done

# Not in allow list - ask user
jq -n --arg cmd "$ACTUAL_CMD" '{
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "ask",
        "permissionDecisionReason": ("Command not in auto-approve list: " + $cmd)
    }
}'
exit 0
