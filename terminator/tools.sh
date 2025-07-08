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

# Function to limit output lines with head/tail display
limit_output_lines() {
    local file="$1"
    local max_lines="${LLM_AGENT_VAR_MAX_OUTPUT_LINES:-50}"
    local total_lines
    
    if [[ ! -s "$file" ]]; then
        return 0
    fi
    
    total_lines=$(wc -l < "$file")
    
    if [[ $total_lines -le $max_lines ]]; then
        # File is small enough, output everything
        cat "$file"
    else
        # File is too large, show head and tail with summary
        local head_lines=$((max_lines / 2))
        local tail_lines=$((max_lines - head_lines))
        local omitted_lines=$((total_lines - head_lines - tail_lines))
        
        echo "Output limited to $max_lines lines (total: $total_lines lines)"
        echo "--- First $head_lines lines ---"
        head -n "$head_lines" "$file"
        echo ""
        echo "... [$omitted_lines lines omitted] ..."
        echo ""
        echo "--- Last $tail_lines lines ---"
        tail -n "$tail_lines" "$file"
        echo "--- End of output (showing $max_lines of $total_lines lines) ---"
    fi
}

# Safe output function that handles UTF-8 encoding issues
safe_output() {
    local file="$1"
    local description="$2"
    
    if [[ ! -s "$file" ]]; then
        return 0
    fi
    
    # Create a temporary file for processed output
    local temp_processed=$(mktemp)
    
    # Check if file contains valid UTF-8
    if iconv -f utf-8 -t utf-8 "$file" >/dev/null 2>&1; then
        # File is valid UTF-8, process directly
        cp "$file" "$temp_processed"
    else
        # File contains non-UTF-8 characters, convert or warn
        echo "[$description contains non-UTF-8 characters, converting...]" > "$temp_processed"
        # Try to convert to UTF-8, replacing invalid sequences
        if command -v iconv >/dev/null 2>&1; then
            iconv -f utf-8 -t utf-8//IGNORE "$file" 2>/dev/null >> "$temp_processed" || {
                echo "[Unable to convert $description to UTF-8, content skipped]" >> "$temp_processed"
            }
        else
            # Fallback: use tr to remove non-printable characters
            tr -cd '[:print:]\n\t' < "$file" >> "$temp_processed" 2>/dev/null || {
                echo "[Content contains binary data or encoding issues, skipped for safety]" >> "$temp_processed"
            }
        fi
    fi
    
    # Apply line limit and output
    limit_output_lines "$temp_processed" >> "$LLM_OUTPUT"
    
    # Clean up
    rm -f "$temp_processed"
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
    
    # Get configuration values
    local timeout="${LLM_AGENT_VAR_TIMEOUT:-300}"  # Default 5 minutes
    local show_real_time="${LLM_AGENT_VAR_SHOW_REAL_TIME_OUTPUT:-true}"
    
    # Check if auto_approve is enabled (agent variable format: LLM_AGENT_VAR_AUTO_APPROVE)
    if [[ "${LLM_AGENT_VAR_AUTO_APPROVE:-false}" == "true" ]]; then
        echo "Auto-approve enabled, executing command: $argc_command" >> "$LLM_OUTPUT"
    else
        # Guard operation with user confirmation
        if [ -t 1 ]; then
            read -r -p "Execute command: $argc_command [Y/n] " ans
            if [[ "$ans" == "N" || "$ans" == "n" ]]; then
                echo "USER_REJECTED: The user has declined to proceed with the operation." >> "$LLM_OUTPUT"
                echo "Command execution was cancelled by user." >> "$LLM_OUTPUT"
                return 0
            fi
        fi
    fi
    
    echo "Executing command with ${timeout}s timeout: $argc_command" >> "$LLM_OUTPUT"
    echo "----------------------------------------" >> "$LLM_OUTPUT"
    
    # Create temporary files for output and error capture
    local temp_out=$(mktemp)
    local temp_err=$(mktemp)
    local temp_combined=$(mktemp)
    
    # Execute command with timeout and capture output/errors
    set +e
    
    local exit_code=0
    local timed_out=false
    
    if [[ "$show_real_time" == "true" ]]; then
        # Real-time output mode: use timeout and tee to show output immediately with line limit
        local max_lines="${LLM_AGENT_VAR_MAX_OUTPUT_LINES:-50}"
        
        if command -v timeout >/dev/null 2>&1; then
            # Use timeout command if available
            {
                timeout "$timeout" bash -c "
                    exec > >(tee '$temp_out' | head -n '$max_lines' | tee -a '$temp_combined')
                    exec 2> >(tee '$temp_err' | head -n '$max_lines' | tee -a '$temp_combined' >&2)
                    $argc_command
                " 2>&1 | head -n "$max_lines" | tee -a "$LLM_OUTPUT"
                
                # Check if output was truncated in real-time
                local stdout_lines=$(wc -l < "$temp_out" 2>/dev/null || echo "0")
                local stderr_lines=$(wc -l < "$temp_err" 2>/dev/null || echo "0")
                local total_output_lines=$((stdout_lines + stderr_lines))
                
                if [[ $total_output_lines -gt $max_lines ]]; then
                    echo "" >> "$LLM_OUTPUT"
                    echo "[Real-time output limited to $max_lines lines. Total output: $total_output_lines lines]" >> "$LLM_OUTPUT"
                    echo "[Use 'show_real_time_output: false' in config to see full buffered output]" >> "$LLM_OUTPUT"
                fi
            } || {
                exit_code=$?
                if [[ $exit_code -eq 124 ]]; then
                    timed_out=true
                    echo "Command timed out after ${timeout} seconds" >> "$LLM_OUTPUT"
                fi
            }
        else
            # Fallback without timeout command
            echo "Warning: 'timeout' command not available, executing without timeout" >> "$LLM_OUTPUT"
            {
                eval "$argc_command" > >(tee "$temp_out" | head -n "$max_lines" | tee -a "$LLM_OUTPUT") 2> >(tee "$temp_err" | head -n "$max_lines" | tee -a "$LLM_OUTPUT" >&2)
                
                # Check if output was truncated
                local stdout_lines=$(wc -l < "$temp_out" 2>/dev/null || echo "0")
                local stderr_lines=$(wc -l < "$temp_err" 2>/dev/null || echo "0")
                local total_output_lines=$((stdout_lines + stderr_lines))
                
                if [[ $total_output_lines -gt $max_lines ]]; then
                    echo "" >> "$LLM_OUTPUT"
                    echo "[Real-time output limited to $max_lines lines. Total output: $total_output_lines lines]" >> "$LLM_OUTPUT"
                fi
            } || {
                exit_code=$?
            }
        fi
    else
        # Buffered output mode: capture all output then display
        if command -v timeout >/dev/null 2>&1; then
            timeout "$timeout" bash -c "$argc_command" >"$temp_out" 2>"$temp_err" || {
                exit_code=$?
                if [[ $exit_code -eq 124 ]]; then
                    timed_out=true
                fi
            }
        else
            echo "Warning: 'timeout' command not available, executing without timeout" >> "$LLM_OUTPUT"
            eval "$argc_command" >"$temp_out" 2>"$temp_err" || {
                exit_code=$?
            }
        fi
    fi
    
    set -e
    
    echo "" >> "$LLM_OUTPUT"
    echo "----------------------------------------" >> "$LLM_OUTPUT"
    
    # Handle timeout case
    if [[ "$timed_out" == "true" ]]; then
        echo "COMMAND TIMED OUT after ${timeout} seconds" >> "$LLM_OUTPUT"
        echo "You may want to increase the timeout value or optimize the command." >> "$LLM_OUTPUT"
        
        # Show any partial output that was captured
        if [[ -s "$temp_out" ]]; then
            echo "" >> "$LLM_OUTPUT"
            echo "Partial output before timeout:" >> "$LLM_OUTPUT"
            safe_output "$temp_out" "partial output"
        fi
        
        if [[ -s "$temp_err" ]]; then
            echo "" >> "$LLM_OUTPUT"
            echo "Partial error output before timeout:" >> "$LLM_OUTPUT"
            safe_output "$temp_err" "partial error output"
        fi
    elif [[ $exit_code -eq 0 ]]; then
        # Success: show output or confirmation
        if [[ "$show_real_time" != "true" ]]; then
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
            echo "Command executed successfully." >> "$LLM_OUTPUT"
        fi
    else
        # Error: show error information for AI to potentially fix
        echo "Command failed with exit code $exit_code:" >> "$LLM_OUTPUT"
        echo "" >> "$LLM_OUTPUT"
        
        if [[ "$show_real_time" != "true" ]]; then
            if [[ -s "$temp_err" ]]; then
                echo "Error output:" >> "$LLM_OUTPUT"
                safe_output "$temp_err" "error output"
            fi
            
            if [[ -s "$temp_out" ]]; then
                echo "" >> "$LLM_OUTPUT"
                echo "Standard output:" >> "$LLM_OUTPUT"
                safe_output "$temp_out" "standard output"
            fi
        fi
        
        echo "" >> "$LLM_OUTPUT"
        echo "Please review the error and suggest a corrected command if needed." >> "$LLM_OUTPUT"
    fi
    
    # Clean up temp files
    rm -f "$temp_out" "$temp_err" "$temp_combined"
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
