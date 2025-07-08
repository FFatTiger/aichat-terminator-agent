# aichat Terminator Agent

An AI agent that translates natural language into shell commands with built-in safety mechanisms. Every command requires user confirmation before execution unless auto-approve mode is enabled (NOT RECOMMENDED due to extreme security risks).

## Features

- Natural language to shell command translation
- Human-in-the-loop safety: all commands require approval
- **Real-time command output**: See command results as they happen
- **Command timeout protection**: Automatically terminates long-running commands
- **Smart output limiting**: Prevents screen flooding with configurable line limits
- Cross-platform support (macOS, Linux, Windows)
- Session mode for extended workflows
- Configurable timeout, output display modes, and line limits

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

### New Features Examples:

**Real-time output** (commands show output immediately):
```bash
aichat --agent terminator "ping google.com for 10 seconds"
aichat --agent terminator "download a file with wget"
```

**Timeout protection** (commands automatically timeout after 5 minutes by default):
```bash
# This will timeout if it runs longer than configured timeout
aichat --agent terminator "find all files larger than 1GB"
```

**Output limiting** (prevents screen flooding):
```bash
# Large output will be limited to configured max_output_lines (default: 50)
aichat --agent terminator "find all log files"
aichat --agent terminator "list all processes"

# In buffered mode, shows first 25 + last 25 lines with summary
# In real-time mode, truncates output and shows warning
```

**Custom configuration**:
Edit `terminator/config.yaml` for custom settings:
```yaml
# Example: 1-minute timeout, 100 lines output, buffered mode
variables:
  timeout: 60
  max_output_lines: 100
  show_real_time_output: false
```

Then rebuild and test:
```bash
./setup.sh  # Rebuild agent
aichat --agent terminator "your command with large output"
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

### Configuration Options

Edit `terminator/config.yaml` to customize behavior:

```yaml
variables: 
  auto_approve: false                     # Set to true to skip confirmation prompts (⚠️ use with caution)
  timeout: 300                           # Command timeout in seconds (default: 5 minutes)
  show_real_time_output: true            # Show command output in real-time
  max_output_lines: 50                   # Maximum lines of output to display (default: 50)
```

**Configuration explanations:**

- **`timeout`**: Maximum time (in seconds) a command can run before being terminated
  - Default: 300 seconds (5 minutes)
  - Set to 0 to disable timeout (not recommended)
  - Commands that exceed this time will be automatically killed

- **`show_real_time_output`**: Control how command output is displayed
  - `true`: Show output immediately as the command runs (recommended)
  - `false`: Buffer all output and show it only after command completion

- **`max_output_lines`**: Limit the number of output lines displayed
  - Default: 50 lines to keep output manageable
  - When exceeded in buffered mode: shows first N/2 and last N/2 lines with summary
  - When exceeded in real-time mode: truncates output and shows warning
  - Set to a higher value for commands with more expected output

After editing configuration, rebuild the agent:
```bash
./setup.sh
```

### ⚠️ Auto-approve mode (EXTREMELY DANGEROUS):
Setting `auto_approve: true` completely bypasses ALL safety checks

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

