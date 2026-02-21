#!/usr/bin/env bash
# ==============================================================
# Screego ユーザー追加スクリプト
# 使い方: ./scripts/add-user.sh <ユーザー名> <パスワード>
# ==============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
USERS_FILE="$ROOT_DIR/config/users.passwd"

USERNAME="${1:-}"
PASSWORD="${2:-}"

if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
    echo "使い方: $0 <ユーザー名> <パスワード>"
    exit 1
fi

# screego コンテナで hash コマンドを実行してパスワードハッシュを生成
HASH=$(docker run --rm screego/server:latest hash --name "$USERNAME" --pass "$PASSWORD" 2>/dev/null \
       | grep -o "${USERNAME}:.*" || true)

if [ -z "$HASH" ]; then
    # フォールバック: htpasswd を使用
    if command -v htpasswd &>/dev/null; then
        HASH=$(htpasswd -nbB "$USERNAME" "$PASSWORD")
    else
        echo "エラー: Docker または htpasswd が必要です"
        exit 1
    fi
fi

# 既存ユーザーを更新、なければ追加
if grep -q "^${USERNAME}:" "$USERS_FILE" 2>/dev/null; then
    sed -i "s|^${USERNAME}:.*|${HASH}|" "$USERS_FILE"
    echo "ユーザー '${USERNAME}' のパスワードを更新しました"
else
    echo "$HASH" >> "$USERS_FILE"
    echo "ユーザー '${USERNAME}' を追加しました"
fi

echo "設定が有効になるまで screego コンテナを再起動してください:"
echo "  docker compose restart screego"
