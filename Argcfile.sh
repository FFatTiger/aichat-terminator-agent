#!/usr/bin/env bash
set -e

# @cmd Build agent and tools
build() {
    build_agent
}

# @cmd Build the terminator agent
build_agent() {
    echo "Building terminator agent..."
    
    cd terminator
    
    local script_file="tools.sh"
    
    if [[ -f "$script_file" ]]; then
        # Generate functions.json
        local json_schema_file="functions.json"
        argc --argc-export "$script_file" | jq '[.]' > "$json_schema_file"
        echo "Generated terminator/$json_schema_file"
        
        # Create bin directory and binary
        mkdir -p bin
        cp "$script_file" bin/terminator
        chmod +x bin/terminator
        echo "Generated terminator/bin/terminator"
    else
        echo "Warning: $script_file not found in terminator/"
    fi
    
    cd ..
}

# @cmd Link this agent to aichat
link-to-aichat() {
    local aichat_functions_dir
    aichat_functions_dir="$(aichat --info | awk '/^functions_dir/ {$1=""; print $0}' | sed 's/^ *//')"
    
    if [[ -n "$aichat_functions_dir" ]]; then
        # Create agents directory in aichat functions dir
        mkdir -p "$aichat_functions_dir/agents"
        
        # Link the entire terminator directory
        local agent_link="$aichat_functions_dir/agents/terminator"
        if [[ -L "$agent_link" ]]; then
            rm "$agent_link"
        fi
        ln -s "$(pwd)/terminator" "$agent_link"
        echo "Linked terminator agent to $agent_link"
    else
        echo "Error: Could not determine aichat functions directory"
        exit 1
    fi
}

# @cmd Check if all dependencies are installed
check() {
    echo "Checking dependencies..."
    
    if ! command -v argc &> /dev/null; then
        echo "Error: argc is not installed. Please install it with: brew install argc"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        echo "Error: jq is not installed. Please install it with: brew install jq"
        exit 1
    fi
    
    if ! command -v aichat &> /dev/null; then
        echo "Error: aichat is not installed. Please install it first."
        echo "See: https://github.com/sigoden/aichat"
        exit 1
    fi
    
    echo "All dependencies are installed!"
}

eval "$(argc --argc-eval "$0" "$@")"
