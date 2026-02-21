#!/usr/bin/env bash
# ==============================================================
# Screego セットアップスクリプト
# 初回デプロイ時に実行してください: ./scripts/setup.sh
# ==============================================================
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$ROOT_DIR"

# ---------- .env ファイルの確認・生成 ----------
if [ ! -f .env ]; then
    info ".env ファイルが存在しません。テンプレートからコピーします..."
    cp .env.example .env
    warn ".env ファイルを編集して設定を入力してください"
fi

# .env を読み込む
set -o allexport
# shellcheck disable=SC1091
source .env
set +o allexport

# ---------- 必須項目のチェック ----------
if [ -z "${SCREEGO_EXTERNAL_IP:-}" ] || [ "$SCREEGO_EXTERNAL_IP" = "203.0.113.1" ]; then
    error "SCREEGO_EXTERNAL_IP を設定してください (.env ファイル)\n  現在の外部 IP: $(curl -s https://api.ipify.org 2>/dev/null || echo '取得失敗')"
fi

if [ -z "${SCREEGO_SECRET:-}" ] || [ "$SCREEGO_SECRET" = "change-me-to-a-long-random-secret" ]; then
    info "SCREEGO_SECRET を自動生成します..."
    SECRET=$(openssl rand -hex 32)
    sed -i "s|SCREEGO_SECRET=.*|SCREEGO_SECRET=${SECRET}|" .env
    info "シークレットを設定しました"
fi

if [ -z "${DOMAIN:-}" ] || [ "$DOMAIN" = "screego.your-domain.example.com" ]; then
    error "DOMAIN を設定してください (.env ファイル)"
fi

if [ -z "${CERTBOT_EMAIL:-}" ] || [ "$CERTBOT_EMAIL" = "your-email@example.com" ]; then
    error "CERTBOT_EMAIL を設定してください (.env ファイル)"
fi

# ---------- nginx 設定のドメイン置換 ----------
NGINX_CONF="$ROOT_DIR/nginx/conf.d/screego.conf"
if grep -q "SCREEGO_DOMAIN_PLACEHOLDER" "$NGINX_CONF"; then
    info "nginx 設定にドメイン '$DOMAIN' を設定します..."
    sed -i "s/SCREEGO_DOMAIN_PLACEHOLDER/${DOMAIN}/g" "$NGINX_CONF"
fi

# ---------- 必要ディレクトリの作成 ----------
mkdir -p certbot/conf certbot/www config

# ---------- ユーザーの確認 ----------
if ! grep -q "^[^#]" config/users.passwd 2>/dev/null; then
    warn "ユーザーが登録されていません"
    read -p "管理ユーザーを今すぐ追加しますか? [Y/n]: " ADD_USER
    if [[ "${ADD_USER:-Y}" =~ ^[Yy]$ ]]; then
        read -p "ユーザー名: " USERNAME
        read -s -p "パスワード: " PASSWORD
        echo ""
        bash "$SCRIPT_DIR/add-user.sh" "$USERNAME" "$PASSWORD"
    fi
fi

info ""
info "セットアップが完了しました"
info ""
info "次のステップ:"
info "  1. Let's Encrypt 証明書を取得:  make init-ssl"
info "  2. サービスを起動:              make up"
info "  3. ログを確認:                  make logs"
info ""
info "ユーザー追加:  make add-user USER=名前 PASS=パスワード"
