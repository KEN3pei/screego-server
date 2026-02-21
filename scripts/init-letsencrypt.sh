#!/usr/bin/env bash
# ==============================================================
# Let's Encrypt SSL 証明書の初期取得スクリプト
# 初回のみ実行: ./scripts/init-letsencrypt.sh
# ==============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$ROOT_DIR"

# .env を読み込む
if [ ! -f .env ]; then
    echo "エラー: .env ファイルが見つかりません。先に ./scripts/setup.sh を実行してください"
    exit 1
fi
set -o allexport
# shellcheck disable=SC1091
source .env
set +o allexport

DOMAIN="${DOMAIN:?'.env に DOMAIN を設定してください'}"
EMAIL="${CERTBOT_EMAIL:?'.env に CERTBOT_EMAIL を設定してください'}"

echo "ドメイン: $DOMAIN"
echo "メール: $EMAIL"
echo ""

# 仮の自己署名証明書で nginx を起動 (certbot の HTTP チャレンジに必要)
echo ">>> 仮証明書を生成しています..."
mkdir -p "certbot/conf/live/$DOMAIN"

# 仮の DH パラメータ (nginx 起動に必要)
if [ ! -f certbot/conf/ssl-dhparams.pem ]; then
    docker run --rm -v "$(pwd)/certbot/conf:/etc/letsencrypt" certbot/certbot \
        certificates 2>/dev/null || true
fi

# ダミー証明書を作成して nginx を起動できるようにする
if [ ! -f "certbot/conf/live/$DOMAIN/fullchain.pem" ]; then
    docker run --rm \
        -v "$(pwd)/certbot/conf:/etc/letsencrypt" \
        --entrypoint openssl \
        certbot/certbot \
        req -x509 -nodes -newkey rsa:2048 -days 1 \
        -keyout "/etc/letsencrypt/live/$DOMAIN/privkey.pem" \
        -out "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" \
        -subj "/CN=localhost" 2>/dev/null
    echo "ダミー証明書を作成しました"
fi

# nginx 起動
echo ">>> nginx を起動しています..."
docker compose up -d nginx

echo ">>> Let's Encrypt 証明書を取得しています..."
sleep 3

docker compose run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email "$EMAIL" \
    --agree-tos \
    --no-eff-email \
    -d "$DOMAIN"

echo ">>> nginx を再読み込みしています..."
docker compose exec nginx nginx -s reload

echo ""
echo "SSL 証明書の取得が完了しました!"
echo "次のコマンドでサービス全体を起動してください:"
echo "  make up"
