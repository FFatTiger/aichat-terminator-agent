#!/usr/bin/env bash

# Guard an operation with a confirmation prompt.

main() {
    if [ -t 1 ]; then
        confirmation_prompt="${1:-"Are you sure you want to continue?"}"
        read -r -p "$confirmation_prompt [Y/n] " ans
        if [[ "$ans" == "N" || "$ans" == "n" ]]; then
            echo "USER_REJECTED: The user has declined to proceed with the operation."
        fi
    fi
}

main "$@"
