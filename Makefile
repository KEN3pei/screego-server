.PHONY: help setup init-ssl up down restart logs add-user dev status pull

# デフォルトターゲット
help:
	@echo "Screego スクリーン共有サーバー 管理コマンド"
	@echo ""
	@echo "初回セットアップ:"
	@echo "  make setup        - 初期設定 (.env, ドメイン設定)"
	@echo "  make init-ssl     - Let's Encrypt SSL 証明書を取得"
	@echo ""
	@echo "サービス管理:"
	@echo "  make up           - 全サービスをバックグラウンドで起動"
	@echo "  make down         - 全サービスを停止"
	@echo "  make restart      - サービスを再起動"
	@echo "  make logs         - ログをリアルタイム表示"
	@echo "  make status       - コンテナの状態を確認"
	@echo "  make pull         - 最新の Docker イメージを取得"
	@echo ""
	@echo "ユーザー管理:"
	@echo "  make add-user USER=<名前> PASS=<パスワード>"
	@echo ""
	@echo "開発用:"
	@echo "  make dev          - TLS なしで開発サーバーを起動 (ポート 5050)"

# 初回セットアップ
setup:
	@chmod +x scripts/setup.sh scripts/add-user.sh scripts/init-letsencrypt.sh
	@./scripts/setup.sh

# SSL 証明書取得
init-ssl:
	@chmod +x scripts/init-letsencrypt.sh
	@./scripts/init-letsencrypt.sh

# サービス起動
up:
	@docker compose up -d
	@echo ""
	@echo "Screego が起動しました"
	@if [ -f .env ]; then . .env && echo "アクセス URL: https://$${DOMAIN}"; fi

# サービス停止
down:
	@docker compose down

# 再起動
restart:
	@docker compose restart

# ログ表示
logs:
	@docker compose logs -f

# screego のみのログ
logs-screego:
	@docker compose logs -f screego

# ステータス確認
status:
	@docker compose ps

# イメージ更新
pull:
	@docker compose pull
	@echo "イメージを更新しました。'make restart' で再起動してください"

# ユーザー追加
add-user:
	@if [ -z "$(USER)" ] || [ -z "$(PASS)" ]; then \
		echo "使い方: make add-user USER=<ユーザー名> PASS=<パスワード>"; \
		exit 1; \
	fi
	@chmod +x scripts/add-user.sh
	@./scripts/add-user.sh "$(USER)" "$(PASS)"

# 開発用サーバー起動 (TLS なし)
dev:
	@docker compose -f docker-compose.dev.yml up
