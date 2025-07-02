#!/usr/bin/env bash
set -e

# @env LLM_OUTPUT=/dev/stdout The output path

# Get the real path of this script, resolving symlinks
SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
ROOT_DIR="${LLM_ROOT_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"

# @cmd Execute the shell command with user confirmation
# @option --command! The command to execute
execute_command() {
    # If the first argument looks like JSON, parse it (when called by aichat)
    if [[ "$1" =~ ^\{.*\}$ ]]; then
        # Parse JSON using jq to extract the command
        local json_input="$1"
        argc_command=$(echo "$json_input" | jq -r '.command')
    else
        # Use the argc_command variable set by argc
        : # argc_command should already be set
    fi
    
    "$ROOT_DIR/utils/guard_operation.sh" "Execute command: $argc_command"
    eval "$argc_command" >> "$LLM_OUTPUT"
}

# See more details at https://github.com/sigoden/argc
# Ensure argc is available by checking both system PATH and Linuxbrew
if command -v argc >/dev/null 2>&1; then
    ARGC_CMD="argc"
elif [ -x "/home/linuxbrew/.linuxbrew/bin/argc" ]; then
    ARGC_CMD="/home/linuxbrew/.linuxbrew/bin/argc"
else
    echo "Error: argc not found. Please install argc." >&2
    exit 1
fi

# Check if we're being called with JSON arguments (by aichat)
if [[ "$2" =~ ^\{.*\}$ ]]; then
    # aichat is calling us with: script_name execute_command {"command":"value"}
    execute_command "$2"
else
    # Normal argc processing
    eval "$($ARGC_CMD --argc-eval "$0" "$@")"
fi
