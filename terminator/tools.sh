#!/usr/bin/env bash
set -e

# @env LLM_OUTPUT=/dev/stdout The output path

ROOT_DIR="${LLM_ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# @cmd Execute the shell command with user confirmation
# @option --command! The command to execute
execute_command() {
    "$ROOT_DIR/utils/guard_operation.sh" "Execute command: $argc_command"
    eval "$argc_command" >> "$LLM_OUTPUT"
}

# See more details at https://github.com/sigoden/argc
eval "$(argc --argc-eval "$0" "$@")"
