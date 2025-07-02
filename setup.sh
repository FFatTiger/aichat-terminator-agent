#!/bin/bash
set -e

echo "🤖 Setting up aichat Terminator Agent..."

# Check dependencies
echo "📋 Checking dependencies..."
./Argcfile.sh check

# Build the agent
echo "🔨 Building agent..."
./Argcfile.sh build

# Link to aichat
echo "🔗 Linking to aichat..."
./Argcfile.sh link-to-aichat

echo "✅ Setup complete!"
echo ""
echo "🎯 You can now use the agent with:"
echo "   aichat --agent terminator \"your command here\""
echo ""
echo "📖 Examples:"
echo "   aichat --agent terminator \"show me the current directory\""
echo "   aichat --agent terminator \"list all files\""
echo "   aichat --agent terminator \"check disk usage\""
