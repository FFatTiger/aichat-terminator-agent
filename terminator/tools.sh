#!/usr/bin/env bash
set -e

# @env LLM_OUTPUT=/dev/stdout The output path

# Get the real path of this script, resolving symlinks
SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
# Calculate ROOT_DIR: if we're in bin/ subdirectory, go up 2 levels; otherwise go up 1 level
if [[ "$(basename "$SCRIPT_DIR")" == "bin" ]]; then
    ROOT_DIR="${LLM_ROOT_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
else
    ROOT_DIR="${LLM_ROOT_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"
fi

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
    
    # Validate that argc_command is not empty
    if [[ -z "$argc_command" ]]; then
        echo "Error: No command provided" >> "$LLM_OUTPUT"
        return 1
    fi
    
    "$ROOT_DIR/utils/guard_operation.sh" "Execute command: $argc_command"
    
    # Create temporary files for output and error capture
    local temp_out=$(mktemp)
    local temp_err=$(mktemp)
    
    # Execute command and capture output/errors (temporarily disable set -e)
    set +e
    eval "$argc_command" >"$temp_out" 2>"$temp_err"
    local exit_code=$?
    set -e
    
    # Output results to LLM
    if [[ $exit_code -eq 0 ]]; then
        # Success: show output or confirmation
        if [[ -s "$temp_out" ]]; then
            # Command has output
            cat "$temp_out" >> "$LLM_OUTPUT"
        else
            # Command executed successfully but no output
            echo "Command executed successfully (no output)." >> "$LLM_OUTPUT"
        fi
        
        if [[ -s "$temp_err" ]]; then
            echo "" >> "$LLM_OUTPUT"
            echo "Command executed successfully, but had warnings:" >> "$LLM_OUTPUT"
            cat "$temp_err" >> "$LLM_OUTPUT"
        fi
    else
        # Error: show error information for AI to potentially fix
        echo "Command failed with exit code $exit_code:" >> "$LLM_OUTPUT"
        echo "" >> "$LLM_OUTPUT"
        echo "Error output:" >> "$LLM_OUTPUT"
        cat "$temp_err" >> "$LLM_OUTPUT"
        if [[ -s "$temp_out" ]]; then
            echo "" >> "$LLM_OUTPUT"
            echo "Standard output:" >> "$LLM_OUTPUT"
            cat "$temp_out" >> "$LLM_OUTPUT"
        fi
        echo "" >> "$LLM_OUTPUT"
        echo "Please review the error and suggest a corrected command if needed." >> "$LLM_OUTPUT"
    fi
    
    # Clean up temp files
    rm -f "$temp_out" "$temp_err"
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
