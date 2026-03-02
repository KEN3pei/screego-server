# Screego K8s マニフェスト

Tailscale 環境の自宅 K8s クラスターに Screego をデプロイするためのマニフェストです。
HTTP のみ（TLS なし）で動作し、Tailscale ネットワーク内のメンバーのみアクセスできます。

## ファイル構成

```
manifests/
├── namespace.yaml                  # screego Namespace
├── sealed-secrets-controller.yaml  # Sealed Secrets Controller (参照用)
├── screego-secret.yaml             # 平文 Secret テンプレート (Git 管理外)
├── screego-sealed-secret.yaml      # 暗号化済み SealedSecret (Git 管理対象)
├── screego-configmap.yaml          # 各種設定値
├── screego-deployment.yaml         # Deployment (hostNetwork: true)
└── screego-service.yaml            # Service (ClusterIP)
```

## 設計のポイント

### hostNetwork: true
`hostNetwork: true` を使用することで：
- ノードのネットワークをそのまま使うため `50000-50200/udp`（TURN リレーポート）が自動的に使える
- NodePort の設定が不要
- `SCREEGO_EXTERNAL_IP` に Tailscale の IP を設定するだけで動作する

### アクセス制限
- Tailscale ネットワーク内のメンバーのみアクセス可能
- インターネットからは到達不可能

### Secret 管理 (Sealed Secrets)
- 平文の `screego-secret.yaml` は Git 管理外（`.gitignore` 済み）
- `kubeseal` で暗号化した `screego-sealed-secret.yaml` のみ Git に push する
- 復号はクラスター内の Sealed Secrets Controller が自動で行う

---

## 初回セットアップ

### 1. Sealed Secrets Controller をインストール

```bash
# Helm でインストール（推奨）
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm repo update
helm install sealed-secrets -n kube-system sealed-secrets/sealed-secrets

# Controller の起動を確認
kubectl get pods -n kube-system | grep sealed-secrets
```

### 2. kubeseal CLI をインストール

```bash
# macOS
brew install kubeseal

# Linux
KUBESEAL_VERSION=$(curl -s https://api.github.com/repos/bitnami-labs/sealed-secrets/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/v//')
curl -OL "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz"
tar -xvzf kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz kubeseal
sudo install -m 755 kubeseal /usr/local/bin/kubeseal
```

### 3. Namespace を作成

```bash
kubectl apply -f manifests/namespace.yaml
```

### 4. SCREEGO_SECRET を生成

```bash
openssl rand -hex 32
```

### 5. users.passwd を生成

```bash
htpasswd -nbB admin yourpassword
```

### 6. screego-secret.yaml に値を設定

`manifests/screego-secret.yaml` を編集して手順 4・5 の値を設定する。

```yaml
stringData:
  SCREEGO_SECRET: "生成したシークレット"
  users.passwd: "admin:$2y$..."
```

### 7. kubeseal で暗号化

```bash
kubeseal --format yaml < manifests/screego-secret.yaml > manifests/screego-sealed-secret.yaml
```

### 8. SCREEGO_EXTERNAL_IP を設定

Tailscale IP を確認して `screego-configmap.yaml` の `SCREEGO_EXTERNAL_IP` に設定する。

```bash
tailscale ip
```

### 9. デプロイ

```bash
kubectl apply -f manifests/
```

### 10. 動作確認

```bash
kubectl get pods -n screego
kubectl logs -n screego deploy/screego
```

---

## Secret を更新するとき

```bash
# screego-secret.yaml を編集後、再度 kubeseal で暗号化
kubeseal --format yaml < manifests/screego-secret.yaml > manifests/screego-sealed-secret.yaml

# クラスターに適用
kubectl apply -f manifests/screego-sealed-secret.yaml

# Pod を再起動して新しい Secret を反映
kubectl rollout restart -n screego deploy/screego
```

---

## アクセス方法

Tailscale ネットワーク内のメンバーは以下でアクセスできる：

```
# Tailscale IP で直接アクセス
http://100.x.x.x:5050

# MagicDNS が有効な場合はホスト名でアクセス可能
http://controlplane-01:5050
```

---

## 日常操作

```bash
# Pod の状態確認
kubectl get pods -n screego

# ログ確認
kubectl logs -n screego deploy/screego

# 再起動
kubectl rollout restart -n screego deploy/screego

# 削除
kubectl delete -f manifests/
```

---

## 注意事項

- `screego-secret.yaml`（平文）は `.gitignore` に含まれており Git にコミットされない
- `screego-sealed-secret.yaml`（暗号化済み）のみ Git に push する
- Sealed Secrets の秘密鍵はクラスター内にのみ存在するため、クラスターを再構築する場合は秘密鍵のバックアップが必要
  ```bash
  # 秘密鍵のバックアップ
  kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > sealed-secrets-key-backup.yaml
  ```
