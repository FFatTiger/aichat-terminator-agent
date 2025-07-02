# aichat Terminator Agent

An AI agent that translates natural language into shell commands with built-in safety mechanisms. Every command requires user confirmation before execution.

## Features

- Natural language to shell command translation
- Human-in-the-loop safety: all commands require approval
- Cross-platform support (macOS, Linux, Windows)
- Session mode for extended workflows

## Installation

### Prerequisites

Required tools:
- [aichat](https://github.com/sigoden/aichat) - The core LLM CLI tool
- [argc](https://github.com/sigoden/argc) - Command parser
- [jq](https://jqlang.github.io/jq/) - JSON processor

**Installation options:**
- **macOS/Linux**: Use [Homebrew](https://brew.sh/) to install all dependencies
- **Ubuntu/Debian**: Use `apt` for jq, install argc and aichat manually
- **Other platforms**: Follow individual project installation guides

### Setup

```bash
git clone https://github.com/your-username/aichat-terminator-agent.git
cd aichat-terminator-agent
./setup.sh
```

Verify installation:
```bash
aichat --list-agents  # Should show 'terminator'
```

## Usage

### Basic usage:
```bash
aichat --agent terminator "list all files"
aichat --agent terminator "show git status"
aichat --agent terminator "check disk usage"
```
### Interactive session:

Enter REPL mode:
```bash
aichat --agent terminator --session
```

Then chat in session:
```bash
terminator>temp) create a test.txt file                                                                                                                                                 0
I will create a file named "test.txt" in the current directory. This file will be empty initially. The command I'll use is `touch test.txt`, which safely creates an empty file if it does not exist, or updates the timestamp if it does.

Executing the command now.
Call terminator execute_command {"command":"touch test.txt"}
Execute command: touch test.txt [Y/n] y

terminator>temp) delete test file                                                                                                                                                 518(0%)
I will delete the "test.txt" file from the current directory. This command will remove the file permanently from the system.

The command I'll use is `rm test.txt`.

Executing the command now.
Call terminator execute_command {"command":"rm test.txt"}
Execute command: rm test.txt [Y/n] y
```

## ⚠️ Security Warning

**IMPORTANT: This tool executes shell commands based on AI interpretation.**

- **Always review commands before confirming** - The AI may misunderstand your request
- **Never run as root/administrator** - Use regular user privileges only  
- **Test in safe environments first** - Don't use on production systems initially
- **Commands execute with your permissions** - They can modify/delete files you have access to

**Type 'n' to cancel any command you're unsure about.**

## Troubleshooting

Manual setup:
```bash
./Argcfile.sh check     # Verify dependencies
./Argcfile.sh reinstall # Clean reinstall
```

## Disclaimer

This tool executes shell commands based on AI interpretation. Always review commands before execution. The authors are not responsible for any damages or data loss. Use at your own risk.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

