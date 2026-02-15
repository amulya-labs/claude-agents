#!/bin/bash
# Claude Code PreToolUse hook for Bash command validation
# Validates commands against allow/deny/ask patterns
# Handles command combinations (pipes, chains, subshells)

set -e

# Read JSON input from stdin
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Exit early if no command
[[ -z "$COMMAND" ]] && exit 0

# Output helper functions
output_deny() {
    local reason="$1"
    jq -n --arg reason "Blocked: $reason" '{
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": $reason
        }
    }'
}

output_ask() {
    local reason="$1"
    jq -n --arg reason "$reason" '{
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "ask",
            "permissionDecisionReason": $reason
        }
    }'
}

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
            # Extract the rest after VAR=
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

# Split command into segments on &&, ||, ; (outside quotes)
# Each segment is validated independently
split_commands() {
    local cmd="$1"
    local current="" quote="" char prev=""
    local i=0
    local len=${#cmd}

    while (( i < len )); do
        char="${cmd:$i:1}"
        if (( i > 0 )); then
            prev="${cmd:$((i-1)):1}"
        else
            prev=""
        fi

        # Track quotes (ignore escaped quotes)
        if [[ "$char" == '"' || "$char" == "'" ]] && [[ "$prev" != \\ ]]; then
            if [[ -z "$quote" ]]; then
                quote="$char"
            elif [[ "$quote" == "$char" ]]; then
                quote=""
            fi
        fi

        # Split on && || ; outside quotes
        if [[ -z "$quote" ]]; then
            if [[ "${cmd:$i:2}" == "&&" || "${cmd:$i:2}" == "||" ]]; then
                [[ -n "$current" ]] && printf '%s\n' "$current"
                current=""
                i=$((i + 2))
                continue
            elif [[ "$char" == ";" ]]; then
                [[ -n "$current" ]] && printf '%s\n' "$current"
                current=""
                i=$((i + 1))
                continue
            fi
        fi

        current+="$char"
        i=$((i + 1))
    done
    [[ -n "$current" ]] && printf '%s\n' "$current"
}

# Clean a command segment: strip leading/trailing whitespace, subshell chars, env vars
clean_segment() {
    local segment="$1"

    # Strip leading/trailing whitespace
    segment="${segment#"${segment%%[![:space:]]*}"}"
    segment="${segment%"${segment##*[![:space:]]}"}"

    # Strip leading subshell/grouping characters: ( {
    while [[ "$segment" =~ ^[\(\{] ]]; do
        segment="${segment:1}"
        segment="${segment#"${segment%%[![:space:]]*}"}"
    done

    # Strip trailing subshell/grouping characters: ) }
    while [[ "$segment" =~ [\)\}]$ ]]; do
        segment="${segment%?}"
        segment="${segment%"${segment##*[![:space:]]}"}"
    done

    # Strip env var prefixes
    segment=$(strip_env_vars "$segment")

    echo "$segment"
}

# === DENY PATTERNS (truly catastrophic - never allow) ===
DENY_PATTERNS=(
    # Privilege escalation
    "^sudo "
    "^su "
    "^doas "

    # Catastrophic file deletion
    "^rm -rf /$"
    "^rm -rf /\*"
    "^rm -rf ~"
    "^rm -rf \.\$"
    "^rm -rf \*$"
    " rm -rf /$"
    " rm -rf /\*"

    # Disk/partition destruction
    "^dd if=.*/dev/"
    "^dd of=/dev/"
    "^mkfs\."
    "^fdisk "
    "^parted "

    # System shutdown
    "^reboot"
    "^shutdown"
    "^poweroff"
    "^halt$"
    "^init 0"
    "^init 6"

    # Fork bombs
    ":.*\\(\\).*\\{.*:\\|"

    # History destruction
    "^history -c"
    "^history -w /dev/null"
)

# === ASK PATTERNS (risky but useful - prompt user for confirmation) ===
ASK_PATTERNS=(
    # Git destructive operations
    "^git push --force"
    "^git push -f "
    "^git reset --hard"
    "^git clean -fd"
    "^git rebase"
    "^git merge"
    "^git cherry-pick"
    "^git revert"
    "^git stash drop"
    "^git stash clear"
    "^git branch -[dD]"

    # Git push to main/master (should prompt)
    "^git push .* main$"
    "^git push .* master$"
    "^git push origin main"
    "^git push origin master"

    # Package publishing (should prompt)
    "^npm publish"
    "^yarn publish"
    "^pnpm publish"
    "^cargo publish"
    "^poetry publish"
    "^twine upload"
    "^gh release create"

    # Database destructive SQL
    "^psql .*DROP"
    "^psql .*TRUNCATE"
    "^mysql .*DROP"

    # GitHub operations that modify state
    "^gh pr merge"
    "^gh pr close"
    "^gh pr ready"
    "^gh repo delete"
    "^gh repo archive"
    "^gh issue close"
    "^gh release delete"
    "^gh run cancel"

    # File permission changes
    "^chmod 777"
    "^chmod -R 777"
    "^chown "
    "^chgrp "

    # Docker cleanup/control
    "^docker system prune"
    "^docker volume prune"
    "^docker network prune"
    "^docker image prune"
    "^docker rmi"
    "^docker rm "
    "^docker stop"
    "^docker kill"
    "^docker container rm"
    "^docker container stop"

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

    # Cloud mutations
    "aws .* delete"
    "aws .* remove"
    "aws .* terminate"
    "aws .* create"
    "aws .* put"
    "aws .* update"
    "gcloud .* delete"
    "gcloud .* create"
    "az .* delete"
    "az .* create"

    # Process control
    "^kill "
    "^killall"
    "^pkill"

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

    # Firewall
    "^iptables"
    "^ip6tables"
    "^ufw "
    "^firewall-cmd"
    "^nft "

    # User/cron management
    "^crontab"
    "^visudo"
    "^passwd"
    "^useradd"
    "^userdel"
    "^usermod"
    "^groupadd"
    "^groupdel"

    # Secrets encryption
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

    # Potentially destructive rm
    "^rm -r"
    "^rm -f"

    # Dangerous xargs patterns
    "xargs.*rm"
    "xargs.*mv "
    "xargs.*chmod"
    "xargs.*chown"

    # Dangerous find -exec patterns
    "find.*-exec.*rm"
    "find.*-exec.*chmod"
    "find.*-delete"

    # Arbitrary code execution via pipes
    "\\| *sh$"
    "\\| *bash$"
    "\\| *zsh$"
    "^eval "
    "source /tmp/"
    "source /var/tmp/"
    "\\. /tmp/"
    "\\. /var/tmp/"
)

# === ALLOW PATTERNS (auto-approve if matched and not denied) ===
ALLOW_PATTERNS=(
    # === Shell Constructs & Builtins ===
    "^\\("                # Subshell start
    "^\\{"                # Command grouping start
    "^:$"                 # Bash no-op
    "^true$"              # No-op success
    "^false$"             # No-op failure
    "^sleep "             # Time delay
    "^read "              # Shell input
    "^wait"               # Wait for jobs
    "^set "               # Shell options
    "^return"             # Function return
    "^exit"               # Script exit
    "^local "             # Local vars
    "^test$"              # Test without args
    "^\\[$"               # Test bracket without args

    # === Path Utilities ===
    "^basename"           # Path manipulation
    "^dirname"            # Path manipulation
    "^realpath"           # Path resolution
    "^readlink"           # Symlink resolution
    "^mktemp"             # Temp file creation
    "^seq "               # Sequence generation
    "^rev"                # Reverse text
    "^yes "               # Repeated output

    # === Missing Basics (Critical) ===
    "^cd "                # Change directory
    "^less"               # Pager
    "^bat"                # Modern cat replacement
    "^watch "             # Watch command output
    "^man "               # Manual pages
    "--version$"          # Any --version flag
    "--help$"             # Any --help flag

    # === Shell Builtins & Navigation ===
    "^pushd"              # Push directory
    "^popd"               # Pop directory
    "^dirs"               # Directory stack
    "^history"            # Shell history (read)
    "^jobs"               # Background jobs
    "^fg"                 # Foreground
    "^bg"                 # Background
    "^source "            # Source scripts
    "^\. "                # Dot source
    "^export "            # Export variables
    "^alias"              # View aliases
    "^declare"            # Variable inspection

    # === C/C++ Toolchain ===
    "^gcc"                # GNU C compiler
    "^g\+\+"              # GNU C++ compiler
    "^clang"              # LLVM compiler
    "^cc "                # C compiler
    "^c\+\+ "             # C++ compiler
    "^ld "                # Linker
    "^ar "                # Archive tool
    "^nm "                # Symbol table
    "^objdump"            # Object dump
    "^ldd "               # Library dependencies
    "^pkg-config"         # Package config
    "^strip"              # Strip symbols

    # === Additional Language Ecosystems ===
    # Haskell
    "^ghc"
    "^ghci"
    "^stack "
    "^cabal "
    "^hlint"

    # Clojure
    "^clj "
    "^clojure"
    "^lein"

    # Dart/Flutter
    "^dart "
    "^flutter"
    "^pub "

    # R
    "^R "
    "^Rscript"

    # Julia
    "^julia"

    # Solidity/Web3
    "^solc"
    "^hardhat"
    "^forge "
    "^cast "
    "^anvil"

    # Protocol Buffers
    "^protoc"
    "^grpcurl"
    "^buf "

    # === DevOps/Cloud Tools ===
    # Local K8s
    "^kind "
    "^minikube"
    "^k3d"

    # K8s utilities
    "^kubectx"
    "^kubens"
    "^stern "
    "^krew"

    # CI/CD local
    "^act"                # GitHub Actions local runner

    # Cloud platforms
    "^vercel"
    "^netlify"
    "^flyctl"
    "^railway"
    "^heroku"
    "^cloudflared"
    "^ngrok"
    "^wrangler"           # Cloudflare Workers
    "^doctl"              # DigitalOcean
    "^eksctl"             # AWS EKS
    "^sam "               # AWS SAM

    # Database tools
    "^pgcli"
    "^mycli"
    "^litecli"
    "^usql"
    "^pg_dump"
    "^pg_restore"
    "^mysqldump"
    "^mongodump"

    # Observability
    "^promtool"
    "^logcli"

    # === Text Processing & Utils ===
    "^column"
    "^fold"
    "^nl "
    "^paste"
    "^shuf"
    "^tac"
    "^iconv"
    "^dos2unix"
    "^unix2dos"
    "^strings"
    "^bc "                # Calculator
    "^expr"               # Calculator

    # === Compression (expanded) ===
    "^bzip2"
    "^bunzip2"
    "^bzcat"
    "^xz "
    "^unxz"
    "^xzcat"
    "^zstd"
    "^unzstd"
    "^zstdcat"
    "^lz4"
    "^7z "
    "^rar "
    "^unrar"

    # === System Inspection ===
    "^lscpu"
    "^lsmem"
    "^lsblk"
    "^lspci"
    "^lsusb"
    "^nproc"
    "^sensors"
    "^inxi"
    "^neofetch"
    "^strace"
    "^ltrace"
    "^perf "
    "^valgrind"

    # === Command Wrappers ===
    "^unbuffer"
    "^stdbuf"
    "^setsid"
    "^parallel"           # GNU Parallel
    "^chronic"            # Moreutils
    "^sponge"             # Moreutils

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

# Check a single command segment against patterns
# Returns: "deny", "ask", or "allow"
# Also sets MATCH_REASON with the matched pattern or reason
check_segment() {
    local segment="$1"
    MATCH_REASON=""

    # Check DENY patterns first
    for pattern in "${DENY_PATTERNS[@]}"; do
        if echo "$segment" | grep -qE -- "$pattern"; then
            MATCH_REASON="matches deny pattern '$pattern'"
            echo "deny"
            return
        fi
    done

    # Check ASK patterns
    for pattern in "${ASK_PATTERNS[@]}"; do
        if echo "$segment" | grep -qE -- "$pattern"; then
            MATCH_REASON="matches pattern '$pattern'"
            echo "ask"
            return
        fi
    done

    # Check ALLOW patterns
    for pattern in "${ALLOW_PATTERNS[@]}"; do
        if echo "$segment" | grep -qE -- "$pattern"; then
            echo "allow"
            return
        fi
    done

    # Not in any list
    MATCH_REASON="not in auto-approve list"
    echo "ask"
}

# Split command into segments and validate each
mapfile -t SEGMENTS < <(split_commands "$COMMAND")

final_decision="allow"
final_reason=""
final_segment=""

for segment in "${SEGMENTS[@]}"; do
    # Clean the segment (strip whitespace, subshell chars, env vars)
    cleaned=$(clean_segment "$segment")

    # Skip empty segments
    [[ -z "$cleaned" ]] && continue

    # Check this segment
    decision=$(check_segment "$cleaned")

    case "$decision" in
        deny)
            # Immediately deny - no need to check further
            output_deny "Segment '$cleaned' $MATCH_REASON"
            exit 0
            ;;
        ask)
            # Track that we need to ask, but keep checking for deny
            if [[ "$final_decision" != "ask" ]]; then
                final_decision="ask"
                final_reason="$MATCH_REASON"
                final_segment="$cleaned"
            fi
            ;;
        allow)
            # Only matters if everything else is also allow
            ;;
    esac
done

# Output final decision
if [[ "$final_decision" == "ask" ]]; then
    output_ask "Segment '$final_segment' $final_reason"
fi
# else: allow (no output)
exit 0
