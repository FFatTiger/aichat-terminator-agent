# aichat Terminator Agent

An AI agent that translates natural language into shell commands with built-in safety mechanisms. Every command requires user confirmation before execution unless auto-approve mode is enabled (NOT RECOMMENDED due to extreme security risks).

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

### ⚠️ Auto-approve mode (EXTREMELY DANGEROUS):
To skip confirmation prompts, edit `terminator/config.yaml`:
```yaml
variables: 
  auto_approve: true    # 🚨 DANGER: Completely bypasses ALL safety checks
```

After editing, rebuild the agent:
```bash
./setup.sh
```

🚨 **CRITICAL WARNING**: Auto-approve mode is EXTREMELY DANGEROUS and can cause IRREVERSIBLE DAMAGE to your system:

- **PERMANENT DATA LOSS**: Commands can delete files, databases, or entire directories without warning
- **SYSTEM CORRUPTION**: May modify critical system files or configurations
- **SECURITY BREACHES**: Could execute malicious commands if AI is compromised or misunderstands instructions
- **NETWORK DAMAGE**: May perform destructive network operations or expose sensitive data
- **FINANCIAL LIABILITY**: Automated commands could trigger costly cloud operations or services

**NEVER USE AUTO-APPROVE ON:**
- Production systems
- Systems with important data
- Shared or corporate environments
- Systems you don't fully control

**DISCLAIMER**: By enabling auto-approve mode, you acknowledge that you understand the extreme risks and accept FULL RESPONSIBILITY for any damage, data loss, security breaches, or other consequences. The authors and contributors of this software are NOT LIABLE for any damages whatsoever, including but not limited to data loss, system corruption, financial losses, or security incidents resulting from the use of auto-approve mode.

## ⚠️ Security Warning

**IMPORTANT: This tool executes shell commands based on AI interpretation.**

- **Always review commands before confirming** - The AI may misunderstand your request
- **Never run as root/administrator** - Use regular user privileges only  
- **Test in safe environments first** - Don't use on production systems initially
- **Commands execute with your permissions** - They can modify/delete files you have access to
- **Auto-approve mode is EXTREMELY DANGEROUS** - Setting `auto_approve: true` bypasses ALL safety checks and can cause IRREVERSIBLE DAMAGE

**Type 'n' to cancel any command you're unsure about. NEVER enable auto-approve unless you fully understand the extreme risks and accept complete liability for any consequences.**

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

