# My Engineering Portfolio

Go によるアプリケーション開発と、AWS 上のインフラを Terraform で管理する練習・検証用のリポジトリです。

## リポジトリ構成

| パス | 内容 |
|------|------|
| `golang/todo` | PostgreSQL 連携のタスク管理 Web アプリ（認証・HTML テンプレート・JSON API） |
| `golang/bottleneck` | DB アクセスの比較用ミニ HTTP サーバー（クエリ方式とメモリ計測） |
| `terraform/aws` | AWS 向け Terraform（モジュール＋本番想定の `prd` 環境） |
| `daily/` | 学習・作業メモ（日付ファイル） |

---

## 1. Todo Web アプリ（`golang/todo`）

ブラウザ向けのタスク CRUD、サインアップ／ログイン（パスワードは bcrypt）、認証必須ルート、および `/api/tasks` の JSON API を提供する HTTP サーバーです。`docker-compose.yml` でアプリと PostgreSQL をまとめて起動できます。

### 技術スタック

- Go（モジュール名: `todo`）
- PostgreSQL（`github.com/lib/pq`）
- `github.com/joho/godotenv`、 `golang.org/x/crypto/bcrypt`
- Docker / Docker Compose

### 環境変数（`.env`）

アプリは `godotenv` で `.env` を読みます。Compose で動かす場合の例:

- `DB_HOST` … DB サービス名（Compose 内では `db`）
- `DB_PORT` … `5432`
- `DB_USER` / `DB_PASSWORD` … `docker-compose.yml` の `POSTGRES_*` と一致させる
- `DB_NAME` … 利用するデータベース名

初回スキーマ・サンプルデータは `init/init.sql` がコンテナ起動時に流れます。

### 実行例

リポジトリルートから:

```bash
cd golang/todo
# .env を用意（上記変数を設定）
docker compose up --build
```

ブラウザではホストの **8082**（`8082:8080` のマッピング）にアクセスします。

ローカルで `go run` する場合は、PostgreSQL を別途起動し、同じ変数を設定したうえで `cmd` からビルド・実行してください（作業ディレクトリによってテンプレートパスが変わる点に注意）。

```bash
cd golang/todo
go mod tidy
go run ./cmd/main.go ./cmd/models.go
```

補助パッケージ `local/` には、メモリ上のタスク一覧など、開発用のローカル実装が含まれます。

---

## 2. Bottleneck 検証（`golang/bottleneck`）

`COUNT` 集計と、大量行をスキャンする方式を切り替えて比較する小さな HTTP サーバーです。ルートは `?type=old` で旧方式、省略時は新方式です。レイテンシログとメモリ使用量のログを出します。

### 実行例

PostgreSQL に `tasks` テーブル等がある前提で、Todo アプリと同様の DB 接続環境変数を `.env` に設定します。

```bash
cd golang/bottleneck
go mod tidy
go run .
```

既定では `:8080` で待ち受けます（Todo アプリと同時起動する場合はポートの競合に注意）。

---

## 3. Terraform（`terraform/aws`）

`modules/` に VPC・SG・EC2・ECS・RDS・IAM・CI/CD などを分割配置し、`environments/prd/` を番号付きスタック（独立 state）として管理しています。スタック一覧・依存関係・apply 順は [`terraform/aws/README.md`](terraform/aws/README.md) を参照。

### 操作例

初回は `bootstrap/` でリモートステート基盤を作成したうえで、各スタックを順に apply します。

```bash
# 例: IAM スタック
cd terraform/aws/environments/prd/00_iam
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

リージョンは `ap-northeast-1` を前提としています。変数・状態ファイル・認証情報は各自の環境に合わせて設定してください。

---

## 今後の伸ばしどころ

- GitHub Actions などでのテスト・静的解析・デプロイの自動化
- Terraform のステート管理とレビュー運用（ワークスペースやロックの整理）
- Todo アプリのテスト整備と Terraform スタックの運用自動化
