#!/usr/bin/env bash
set -e

# @cmd Build agent and tools
build() {
    build_agent
}

# @cmd Force reinstall the entire agent (clean build + relink)
reinstall() {
    echo "🚀 Starting complete reinstallation of terminator agent..."
    echo ""
    
    # Step 1: Force rebuild
    build_agent
    echo ""
    
    # Step 2: Force relink to aichat
    link-to-aichat
    echo ""
    
    echo "✨ Complete reinstallation finished!"
    echo ""
    echo "🎯 You can now use the agent with:"
    echo "   aichat --agent terminator \"your command here\""
    echo ""
    echo "📖 Test it:"
    echo "   aichat --agent terminator \"show me the current directory\""
}

# @cmd Build the terminator agent (force rebuild)
build_agent() {
    echo "🔨 Building terminator agent (force rebuild)..."
    
    cd terminator
    
    local script_file="tools.sh"
    
    if [[ -f "$script_file" ]]; then
        # Force remove existing generated files
        echo "Cleaning existing build files..."
        rm -f functions.json
        rm -rf bin/
        
        # Copy config.yaml if it exists
        if [[ -f "config.yaml" ]]; then
            echo "✅ Found agent config.yaml"
        else
            echo "⚠️  No config.yaml found for agent (this may affect REPL completion)"
        fi
        
        # Generate functions.json using proper method
        local json_schema_file="functions.json"
        local declarations="$($ARGC_CMD --argc-export "$script_file" | \
            jq '[{
                "name": .subcommands[0].name,
                "description": .subcommands[0].describe,
                "parameters": {
                    "type": "object",
                    "properties": (.subcommands[0].flag_options | map(select(.id != "help") | {(.id): {"type": "string", "description": .describe}}) | add),
                    "required": [.subcommands[0].flag_options[] | select(.required == true and .id != "help") | .id]
                },
                "agent": true
            }]')"
        echo "$declarations" > "$json_schema_file"
        echo "✅ Generated terminator/$json_schema_file"
        
        # Create bin directory and binary
        mkdir -p bin
        cp "$script_file" bin/terminator
        # Fix the ROOT_DIR path calculation for bin/terminator (needs to go up two levels instead of one)
        sed -i 's|\$SCRIPT_DIR/\.\.|\$SCRIPT_DIR/../..|g' bin/terminator
        chmod +x bin/terminator
        echo "✅ Generated terminator/bin/terminator"
    else
        echo "❌ Warning: $script_file not found in terminator/"
    fi
    
    cd ..
}

# @cmd Link this agent to aichat (force replace if exists)
link-to-aichat() {
    local aichat_functions_dir
    # Check if aichat is available, try Linuxbrew if not in PATH
    if command -v aichat >/dev/null 2>&1; then
        AICHAT_CMD="aichat"
    elif [ -x "/home/linuxbrew/.linuxbrew/bin/aichat" ]; then
        AICHAT_CMD="/home/linuxbrew/.linuxbrew/bin/aichat"
    else
        echo "Error: aichat not found. Please install aichat." >&2
        exit 1
    fi
    
    aichat_functions_dir="$($AICHAT_CMD --info | awk '/^functions_dir/ {$1=""; print $0}' | sed 's/^ *//')"
    
    if [[ -n "$aichat_functions_dir" ]]; then
        # Create agents directory in aichat functions dir
        mkdir -p "$aichat_functions_dir/agents"
        
        # Force remove any existing terminator installation
        local agent_link="$aichat_functions_dir/agents/terminator"
        if [[ -L "$agent_link" ]] || [[ -d "$agent_link" ]] || [[ -f "$agent_link" ]]; then
            echo "Removing existing terminator installation at $agent_link"
            rm -rf "$agent_link"
        fi
        
        # Create fresh symlink
        ln -s "$(pwd)/terminator" "$agent_link"
        echo "✅ Linked terminator agent to $agent_link (force replaced)"
    else
        echo "Error: Could not determine aichat functions directory"
        exit 1
    fi
}

# @cmd Check if all dependencies are installed
check() {
    echo "Checking dependencies..."
    local all_good=true
    
    # Check argc
    if command -v argc &> /dev/null; then
        echo "✅ argc found in PATH"
    elif [ -x "/home/linuxbrew/.linuxbrew/bin/argc" ]; then
        echo "✅ argc found in Linuxbrew"
    else
        echo "❌ argc not found. Please install it."
        echo "   Ubuntu/Debian: Follow instructions at https://github.com/sigoden/argc"
        echo "   macOS: brew install argc"
        all_good=false
    fi
    
    # Check jq
    if command -v jq &> /dev/null; then
        echo "✅ jq found in PATH"
    else
        echo "❌ jq not found. Please install it."
        echo "   Ubuntu/Debian: sudo apt install jq"
        echo "   macOS: brew install jq"
        all_good=false
    fi
    
    # Check aichat
    if command -v aichat &> /dev/null; then
        echo "✅ aichat found in PATH"
    elif [ -x "/home/linuxbrew/.linuxbrew/bin/aichat" ]; then
        echo "✅ aichat found in Linuxbrew"
    else
        echo "❌ aichat not found. Please install it."
        echo "   See: https://github.com/sigoden/aichat"
        all_good=false
    fi
    
    if [ "$all_good" = true ]; then
        echo "✨ All dependencies are installed!"
        return 0
    else
        echo ""
        echo "💡 Please install the missing dependencies and try again."
        return 1
    fi
}

# Ensure argc is available by checking both system PATH and Linuxbrew
if command -v argc >/dev/null 2>&1; then
    ARGC_CMD="argc"
elif [ -x "/home/linuxbrew/.linuxbrew/bin/argc" ]; then
    ARGC_CMD="/home/linuxbrew/.linuxbrew/bin/argc"
else
    echo "Error: argc not found. Please install argc." >&2
    exit 1
fi

eval "$($ARGC_CMD --argc-eval "$0" "$@")"
