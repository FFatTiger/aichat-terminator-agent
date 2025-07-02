# 🤖 aichat Terminator Agent

> A secure, intelligent command-line agent that translates natural language into shell commands with built-in safety mechanisms.

This project implements a "Warp-like" terminal AI agent using the [aichat](https://github.com/sigoden/aichat) ecosystem. It safely executes shell commands through natural language input while following a strict "Human-in-the-Loop" approach for security.

## ✨ Features

- **🔒 Secure Command Execution**: Every command requires user confirmation before execution
- **🛡️ Safety-First Design**: Built-in rules prevent destructive operations
- **🧠 Natural Language Processing**: Convert plain English to precise shell commands
- **🖥️ System-Aware**: Automatically detects your OS, shell, and environment for optimal command generation
- **⚡ Easy Setup**: One-command installation and setup
- **🔧 Modular Architecture**: Easily extendable with new tools and capabilities

## 🚀 Quick Start

### Prerequisites

You'll need the following tools installed:

```bash
# Install aichat (follow instructions at https://github.com/sigoden/aichat)
# Install argc and jq
brew install argc jq
```

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/aichat-terminator-agent.git
   cd aichat-terminator-agent
   ```

2. **Run the setup script**:
   ```bash
   ./setup.sh
   ```

   This will:
   - Check all dependencies
   - Build the agent and tools
   - Link the agent to your aichat installation

### Usage Examples

```bash
# Basic file operations
aichat --agent terminator "show me the current directory path"
aichat --agent terminator "list all files including hidden ones"
aichat --agent terminator "find all Python files in this directory"

# System information
aichat --agent terminator "show me disk usage"
aichat --agent terminator "check system memory usage"
aichat --agent terminator "display current date and time"

# Git operations
aichat --agent terminator "show git status"
aichat --agent terminator "list recent git commits"

# System-aware operations (automatically adjusts for your OS/shell)
aichat --agent terminator "show detailed system information"  # Uses system_profiler on macOS, systeminfo on Windows
aichat --agent terminator "what shell am I using?"             # Detects your current shell
aichat --agent terminator "show running processes"             # Uses ps on Unix, Get-Process on Windows
```

## 🏗️ Project Structure

```plaintext
aichat-terminator-agent/
├── terminator/
│   ├── index.yaml          # Agent configuration and instructions
│   └── tools.sh            # Command execution tools
├── utils/
│   └── guard_operation.sh  # Safety confirmation utility
├── Argcfile.sh             # Build system and commands
├── setup.sh                # One-click setup script
├── README.md               # This file
└── LICENSE                 # MIT License
```

## 🔒 Security Features

This agent implements multiple layers of security:

1. **Human-in-the-Loop Confirmation**: Every command execution requires explicit user approval
2. **Defensive Prompt Engineering**: Built-in instructions prevent the AI from generating destructive commands
3. **Command Validation**: Safe commands are prioritized, dangerous operations are avoided
4. **Transparent Operation**: All commands are displayed to the user before execution

### Example Security Flow

```bash
$ aichat --agent terminator "remove a test file"

Call terminator execute_command {"command":"rm test.txt"}
Execute command: rm test.txt [Y/n] n
error: aborted!
Error: Tool call exit with 1
```

## 🛠️ Manual Setup (Alternative)

If you prefer to set up manually:

```bash
# Check dependencies
./Argcfile.sh check

# Build the agent
./Argcfile.sh build

# Link to aichat
./Argcfile.sh link-to-aichat
```

## 🧪 Testing

Test the agent with safe commands:

```bash
# Test basic functionality
aichat --agent terminator "what directory am I in?"

# Test with confirmation (type 'y' when prompted)
aichat --agent terminator "show me the date"

# Test cancellation (type 'n' when prompted)
aichat --agent terminator "list files"
```

## 🤝 Contributing

Contributions are welcome! Please feel free to:

1. Fork the repository
2. Create a feature branch
3. Add your improvements
4. Submit a pull request

## 📚 Related Projects

- [aichat](https://github.com/sigoden/aichat) - The core LLM CLI tool
- [llm-functions](https://github.com/sigoden/llm-functions) - Framework for creating LLM tools and agents
- [argc](https://github.com/sigoden/argc) - Command-line argument parser

## ⚠️ Disclaimer

This tool executes shell commands based on AI interpretation. While safety measures are in place, always:

- Review commands before approving them
- Be cautious with file operations
- Test in a safe environment first
- Understand that the AI may misinterpret requests

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

