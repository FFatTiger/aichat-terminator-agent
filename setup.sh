#!/bin/bash
set -e

echo "🤖 Setting up aichat Terminator Agent (Force Replace Mode)..."
echo ""

# Check dependencies
echo "📋 Checking dependencies..."
if ! ./Argcfile.sh check; then
    echo "❌ Dependency check failed. Please install missing dependencies and try again."
    echo ""
    echo "For Ubuntu/Debian:"
    echo "  sudo apt update"
    echo "  sudo apt install curl jq"
    echo "  # Install argc: https://github.com/sigoden/argc"
    echo "  # Install aichat: https://github.com/sigoden/aichat"
    echo ""
    echo "For macOS:"
    echo "  brew install argc jq"
    echo "  # Install aichat: https://github.com/sigoden/aichat"
    exit 1
fi

echo ""

# Force reinstall the agent (clean build + relink)
echo "🚀 Performing complete reinstallation..."
./Argcfile.sh reinstall

echo "✅ Setup complete!"
echo ""
echo "🎯 You can now use the agent with:"
echo "   aichat --agent terminator \"your command here\""
echo ""
echo "📖 Examples:"
echo "   aichat --agent terminator \"show me the current directory\""
echo "   aichat --agent terminator \"list all files\""
echo "   aichat --agent terminator \"check disk usage\""
