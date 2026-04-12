# My Engineering Portfolio

これは、私の技術スキルと学習の軌跡を示すためのポートフォリオプロジェクトです。バックエンドアプリケーション開発と、それを支えるインフラストラクチャの構築・管理能力を示すことを目的としています。

---

## 🚀 Projects

このポートフォリオには、以下のプロジェクトが含まれています。

### 1. Go Task Manager (CLI)

シンプルなコマンドライン（CLI）ベースのタスク管理アプリケーションです。

#### ✨ 主な特徴
- Go言語によるバックエンド開発スキルを示します。
- データベース（PostgreSQL）との連携を実装しています。
- CLIでのインタラクティブな操作が可能です。

#### 🛠️ 使用技術
- **言語**: Go
- **データベース**: PostgreSQL
- **その他**: `godotenv` (環境変数管理), `pq` (Go用PostgreSQLドライバ)

#### 🏃‍♂️ 実行方法 (例)
```bash
# 1. リポジトリをクローン
git clone https://github.com/[your_username]/[your_repository].git
cd portfolio/golang/task_manager

# 2. 環境変数を設定 (.env.exampleをコピー)
cp .env.example .env
# .env ファイルにデータベース接続情報を記述

# 3. 依存関係をインストール
go mod tidy

# 4. アプリケーションを実行
go run .
```
> **Note**: 上記は一般的な実行例です。あなたのプロジェクトに合わせて詳細を追記・修正してください。

---

### 2. Terraform AWS Infrastructure

上記のGoアプリケーションをホストするためのAWSインフラストラクチャをコードで管理（IaC）するプロジェクトです。

#### ✨ 主な特徴
- Terraformを用いた実践的なInfrastructure as Code (IaC) のスキルを示します。
- `modules`を活用し、再利用性と保守性の高い構成を意識しています。
- `environments`で開発・ステージング・本番環境を分離する、実務に近い運用を想定しています。

#### 🏗️ 想定アーキテクチャ
このTerraformコードは、以下のようなAWSリソースを構築することを想定しています。
- **VPC**: プロジェクト専用の独立したネットワーク空間
- **Subnet**: パブリック/プライベートサブネット
- **EC2**: Goアプリケーションを実行する仮想サーバー
- **Security Group**: EC2インスタンスへのアクセスを制御するファイアウォール
- **EIP**: EC2インスタンスに固定IPアドレスを付与
- **IAM Role**: EC2インスタンスに適切な権限を付与

#### 🛠️ 使用技術
- **IaC**: Terraform
- **クラウド**: AWS

#### 🚀 デプロイ方法 (例)
```bash
# 1. Terraformの環境へ移動 (例: 本番環境)
cd portfolio/terraform/aws/enviroments/prd

# 2. Terraformを初期化
terraform init

# 3. 実行計画を確認
terraform plan

# 4. インフラをデプロイ
terraform apply
```
> **Note**: こちらも一般的な実行例です。実際のデプロイ手順に合わせて修正してください。

---

## 🌱 次のステップ (Next Steps)

- **CI/CDパイプラインの構築**: GitHub Actionsなどを利用して、テストとデプロイを自動化する。
- **GoアプリケーションのAPI化**: 現在のCLIアプリをREST APIに変更し、フロントエンドから利用できるようにする。
- **コンテナ化**: Dockerを使ってGoアプリケーションをコンテナ化し、ECSやEKS上での実行を検討する。

---

## 📫 連絡先

- **GitHub**: @[your_github_username]
- **LinkedIn**: [Your LinkedIn Profile URL]
- **Email**: [your.email@example.com]
