#!/usr/bin/env bash
set -e

# @env LLM_OUTPUT=/dev/stdout The output path
# @env LLM_AGENT_VAR_AUTO_APPROVE=false Set to true to skip confirmation prompts

# Get the real path of this script, resolving symlinks
SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
# Calculate ROOT_DIR: if we're in bin/ subdirectory, go up 2 levels; otherwise go up 1 level
if [[ "$(basename "$SCRIPT_DIR")" == "bin" ]]; then
    ROOT_DIR="${LLM_ROOT_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
else
    ROOT_DIR="${LLM_ROOT_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"
fi

# Safe output function that handles UTF-8 encoding issues
safe_output() {
    local file="$1"
    local description="$2"
    
    if [[ ! -s "$file" ]]; then
        return 0
    fi
    
    # Check if file contains valid UTF-8
    if iconv -f utf-8 -t utf-8 "$file" >/dev/null 2>&1; then
        # File is valid UTF-8, output directly
        cat "$file" >> "$LLM_OUTPUT"
    else
        # File contains non-UTF-8 characters, convert or warn
        echo "[$description contains non-UTF-8 characters, converting...]" >> "$LLM_OUTPUT"
        # Try to convert to UTF-8, replacing invalid sequences
        if command -v iconv >/dev/null 2>&1; then
            iconv -f utf-8 -t utf-8//IGNORE "$file" 2>/dev/null >> "$LLM_OUTPUT" || {
                echo "[Unable to convert $description to UTF-8, content skipped]" >> "$LLM_OUTPUT"
            }
        else
            # Fallback: use tr to remove non-printable characters
            tr -cd '[:print:]\n\t' < "$file" >> "$LLM_OUTPUT" 2>/dev/null || {
                echo "[Content contains binary data or encoding issues, skipped for safety]" >> "$LLM_OUTPUT"
            }
        fi
    fi
}

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
    
    # Check if auto_approve is enabled (agent variable format: LLM_AGENT_VAR_AUTO_APPROVE)
    if [[ "${LLM_AGENT_VAR_AUTO_APPROVE:-false}" == "true" ]]; then
        echo "Auto-approve enabled, executing command: $argc_command" >> "$LLM_OUTPUT"
    else
        # Use guard operation for confirmation and capture output
        local guard_output
        guard_output=$("$ROOT_DIR/utils/guard_operation.sh" "Execute command: $argc_command")
        
        # Check if user rejected the operation
        if [[ "$guard_output" == *"USER_REJECTED:"* ]]; then
            echo "$guard_output" >> "$LLM_OUTPUT"
            echo "Command execution was cancelled by user." >> "$LLM_OUTPUT"
            return 0
        fi
    fi
    
    # Create temporary files for output and error capture
    local temp_out=$(mktemp)
    local temp_err=$(mktemp)
    
    # Execute command and capture output/errors (temporarily disable set -e)
    set +e
    
    # Wrap command execution in error handling
    {
        eval "$argc_command" >"$temp_out" 2>"$temp_err"
    } || true  # Ensure we don't exit on command failure
    
    local exit_code=$?
    set -e
    
    # Output results to LLM with safe UTF-8 handling
    if [[ $exit_code -eq 0 ]]; then
        # Success: show output or confirmation
        if [[ -s "$temp_out" ]]; then
            # Command has output - use safe output function
            safe_output "$temp_out" "command output"
        else
            # Command executed successfully but no output
            echo "Command executed successfully (no output)." >> "$LLM_OUTPUT"
        fi
        
        if [[ -s "$temp_err" ]]; then
            echo "" >> "$LLM_OUTPUT"
            echo "Command executed successfully, but had warnings:" >> "$LLM_OUTPUT"
            safe_output "$temp_err" "warning messages"
        fi
    else
        # Error: show error information for AI to potentially fix
        echo "Command failed with exit code $exit_code:" >> "$LLM_OUTPUT"
        echo "" >> "$LLM_OUTPUT"
        echo "Error output:" >> "$LLM_OUTPUT"
        safe_output "$temp_err" "error output"
        
        if [[ -s "$temp_out" ]]; then
            echo "" >> "$LLM_OUTPUT"
            echo "Standard output:" >> "$LLM_OUTPUT"
            safe_output "$temp_out" "standard output"
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
