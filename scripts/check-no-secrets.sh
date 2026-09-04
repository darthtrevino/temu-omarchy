#!/usr/bin/env bash

set -euo pipefail

root=$(git rev-parse --show-toplevel)
mode=${1:---all}
pattern='-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----|A(KIA|SIA)[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{50,}|sk-(proj-)?[A-Za-z0-9_-]{20,}|xox[baprs]-[A-Za-z0-9-]{20,}|AIza[0-9A-Za-z_-]{30,}'
forbidden_name='(^|/)(\.env(\..*)?|id_rsa.*|id_ed25519.*|credentials.*|secrets.*)$|\.(key|pem|p12|pfx|jks)$'

cd "$root"

if [[ "$mode" == "--staged" ]]; then
    if git diff --cached --name-only --diff-filter=ACMR \
        | grep -E "$forbidden_name"; then
        printf 'Refusing commit: staged credential-like filename detected.\n' >&2
        exit 1
    fi

    if git grep --cached -lEI -e "$pattern" -- \
        . \
        ':(exclude)scripts/check-no-secrets.sh' \
        ':(exclude)hooks/pre-commit'; then
        printf 'Refusing commit: staged content resembles a secret key or token.\n' >&2
        exit 1
    fi
else
    status=0
    while IFS= read -r -d '' file; do
        relative=${file#./}
        case "$relative" in
            scripts/check-no-secrets.sh|hooks/pre-commit)
                continue
                ;;
        esac

        if [[ "$relative" =~ $forbidden_name ]]; then
            printf '%s: credential-like filename\n' "$relative" >&2
            status=1
        elif grep -lEI -- "$pattern" "$file" >/dev/null; then
            printf '%s: content resembles a secret key or token\n' "$relative" >&2
            status=1
        fi
    done < <(find . -path ./.git -prune -o -type f -print0)

    if (( status != 0 )); then
        exit "$status"
    fi
fi

printf 'No high-confidence secret patterns found.\n'
