# screego-server デプロイ構成

[screego/server](https://github.com/screego/server) を自宅サーバーへデプロイするための Docker Compose 構成です。

Screego は WebRTC を使った開発者向け画面共有ツールです。低遅延・高品質で画面を共有でき、内蔵 TURN サーバーにより NAT 越えも対応しています。

## 構成

```
screego-server/
├── docker-compose.yml        # 本番用 (nginx + certbot + screego)
├── docker-compose.dev.yml    # 開発用 (TLS なし、ポート 5050 直接)
├── .env.example              # 環境変数テンプレート
├── Makefile                  # 管理コマンド
├── nginx/
│   ├── nginx.conf            # nginx メイン設定
│   └── conf.d/
│       └── screego.conf      # Screego リバースプロキシ設定
├── config/
│   └── users.passwd          # ユーザーファイル (gitignore 済み)
├── scripts/
│   ├── setup.sh              # 初回セットアップ
│   ├── add-user.sh           # ユーザー追加
│   └── init-letsencrypt.sh  # Let's Encrypt SSL 証明書取得
└── certbot/                  # SSL 証明書データ (gitignore 済み)
```

## 必要条件

- Docker & Docker Compose v2
- 公開ドメイン名 (Let's Encrypt TLS のため)
- 以下のポートを開放:
  - `80/tcp` (HTTP / Let's Encrypt チャレンジ)
  - `443/tcp` (HTTPS)
  - `3478/tcp` + `3478/udp` (TURN サーバー)
  - `50000-50200/udp` (TURN リレーポート範囲)

## 初回セットアップ

### 1. リポジトリをクローン

```bash
git clone https://github.com/KEN3pei/screego-server.git
cd screego-server
```

### 2. 環境変数を設定

```bash
cp .env.example .env
```

`.env` を編集して以下を設定:

| 変数 | 説明 | 例 |
|------|------|-----|
| `SCREEGO_EXTERNAL_IP` | サーバーの外部 IP | `203.0.113.1` または `dns:your.domain.com` |
| `SCREEGO_SECRET` | Cookie 署名用シークレット | `openssl rand -hex 32` で生成 |
| `DOMAIN` | 公開ドメイン名 | `screego.example.com` |
| `CERTBOT_EMAIL` | Let's Encrypt 登録メール | `admin@example.com` |
| `SCREEGO_AUTH_MODE` | 認証モード | `turn`(推奨) / `all` / `none` |

- SCREEGO_EXTERNAL_IP
  - サーバーが固定IPアドレスを持たない場合は、ドメイン名からIPアドレスを取得できます。
    - SCREEGO_EXTERNAL_IP=dns:app.screego.net
  - 使用するDNSサーバーを指定することも可能です。
    - SCREEGO_EXTERNAL_IP=dns:app.screego.net@9.9.9.9:53
  - `curl https://api.ipify.org`で外部IPを確認して設定する。




### 3. セットアップを実行

```bash
make setup
```

### 4. ユーザーを追加

```bash
make add-user USER=admin PASS=yourpassword
```

### 5. SSL 証明書を取得

```bash
make init-ssl
```

### 6. サービスを起動

```bash
make up
```

`https://DOMAIN` でアクセスできます。

---

## 日常操作

```bash
# ログ確認
make logs

# 状態確認
make status

# 再起動
make restart

# イメージ更新後に再起動
make pull && make restart

# ユーザー追加
make add-user USER=username PASS=password

# 停止
make down
```

## 開発・テスト用 (TLS なし)

```bash
make dev
```

`http://localhost:5050` でアクセスできます。

## ネットワーク構成

```
クライアント
    │
    ├─ HTTPS (443) ──→ nginx ──→ screego:5050 (HTTP)
    │                   (TLS 終端 + WebSocket プロキシ)
    │
    └─ TURN (3478 TCP/UDP) ──→ screego (TURN サーバー)
       TURN relay (50000-50200/udp)
```

- **nginx**: TLS 終端・リバースプロキシ
- **screego**: アプリケーション本体 + 内蔵 TURN サーバー
- **certbot**: Let's Encrypt 証明書の自動更新

## セキュリティ注意事項

- `.env` / `config/users.passwd` / `certbot/` は `.gitignore` に含まれており、Git に含まれません
- `SCREEGO_SECRET` は必ず強力なランダム値を設定してください
- 本番環境では `SCREEGO_AUTH_MODE=turn` 以上を推奨します

## 参考

- [screego/server 公式](https://github.com/screego/server)
- [Screego ドキュメント](https://screego.net)
- [設定オプション一覧](https://screego.net/#/config)
