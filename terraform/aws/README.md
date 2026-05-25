# AWS Terraform

`ap-northeast-1` 向けの Terraform 構成。`bootstrap/` でリモートステート基盤を作成し、`environments/prd/` を番号付きスタックに分割して管理する。

## ディレクトリ構成

| パス | 内容 |
|------|------|
| `bootstrap/` | リモートステート用 S3 バケット・DynamoDB ロックテーブル（初回のみ） |
| `modules/` | 再利用モジュール（VPC、SG、EC2、ECS、RDS、IAM、CI/CD など） |
| `environments/prd/` | 本番想定スタック（スタックごとに独立した state） |

## スタック一覧

| スタック | パス | 主なリソース | 参照する remote state |
|----------|------|--------------|------------------------|
| bootstrap | `bootstrap/` | S3（state）、DynamoDB（lock） | なし |
| 00_iam | `environments/prd/00_iam/` | EC2 用 IAM ロール、ECS タスク実行ロール | なし |
| 01_network | `environments/prd/01_network/` | VPC、サブネット、IGW、ルート（プライベートは NAT なし） | なし |
| 01_network_nat | `environments/prd/01_network_nat/` | NAT Gateway、プライベート RT への 0.0.0.0/0（任意） | `01_network` |
| 02_database | `environments/prd/02_database/` | RDS、web/db 用 SG | `01_network` |
| 03_compute_ec2 | `environments/prd/03_compute_ec2/` | EC2 | `00_iam`, `01_network`, （任意）`02_database` |
| 03_ecr | `environments/prd/03_ecr/` | ECR リポジトリ（イメージ push 先） | なし |
| 04_compute_ecs | `environments/prd/04_compute_ecs/` | ECS（Fargate）+ ALB、ECS/ALB 用 SG | `00_iam`, `01_network`, `03_ecr` |
| 05_cicd | `environments/prd/05_cicd/` | CodeCommit、CodeBuild、CodePipeline | `00_iam`, `04_compute_ecs`, `03_ecr` |

`modules/eip` は Elastic IP 用モジュールだが、現状どのスタックからも未参照。

## 依存関係

```mermaid
flowchart TD
  bootstrap[bootstrap]
  iam[00_iam]
  network[01_network]
  network_nat[01_network_nat]
  database[02_database]
  ec2[03_compute_ec2]
  ecr[03_ecr]
  ecs[04_compute_ecs]
  cicd[05_cicd]

  bootstrap -.->|state 基盤| iam
  bootstrap -.-> network
  bootstrap -.-> database
  bootstrap -.-> ec2
  bootstrap -.-> ecs
  bootstrap -.-> ecr
  bootstrap -.-> cicd

  network --> network_nat
  network --> database
  network --> ec2
  network --> ecs
  iam --> ec2
  iam --> ecs
  iam --> cicd
  database -->|use_database_security_groups=true 時| ec2
  ecr --> ecs
  ecr --> cicd
  ecs --> cicd
```

## apply 順

1. **bootstrap**（アカウント初回のみ）
2. **00_iam** と **01_network**（相互依存なし。並列可）
3. **01_network_nat**（プライベートからインターネット egress が必要なときのみ。`01_network` 完了後）
4. **02_database**（`01_network` 完了後）
5. **03_compute_ec2** と **03_ecr**（`00_iam` + `01_network` 完了後。EC2 と ECR は相互依存なし。並列可）
   - EC2 で `use_database_security_groups = true` の場合は **02_database** も先に apply すること
6. **04_compute_ecs**（`00_iam` + `01_network` + **03_ecr** 完了後。イメージ tag が ECR に存在すること）
7. **05_cicd**（`04_compute_ecs` と `03_ecr` 完了後）

destroy は上記の逆順。

### 既存 `04_cicd` を `05_cicd` にリネームする場合（state 移行）

S3 上の state キーを移し、`backend.hcl` の `key` を `prd/05_cicd/terraform.tfstate` に更新してから再 init する。

```bash
aws s3 mv \
  s3://<terraform_state_bucket>/prd/04_cicd/terraform.tfstate \
  s3://<terraform_state_bucket>/prd/05_cicd/terraform.tfstate

cd terraform/aws/environments/prd/05_cicd
terraform init -backend-config=backend.hcl -reconfigure -migrate-state
```

### 旧 `04_cicd` に ECR が含まれている場合

1. `03_ecr` を apply する前に、旧 CI/CD スタックから ECR リソースを state から外す（`terraform state rm` で `module.ecr` 配下）
2. `03_ecr` を apply（既存リポジトリと同名の場合は `terraform import` で取り込み）
3. `05_cicd` を apply（ECR は `03_ecr` の remote state 参照に切り替わる）

`repository_suffix` は `03_ecr` と `05_cicd` で同じ値に揃えること。

### 既存 `03_compute_ecs` / `04_ecr` を `04_compute_ecs` / `03_ecr` にリネームする場合（state 移行）

S3 上の state キーを移し、各スタックの `backend.hcl` を更新してから再 init する。

```bash
aws s3 mv \
  s3://<terraform_state_bucket>/prd/04_ecr/terraform.tfstate \
  s3://<terraform_state_bucket>/prd/03_ecr/terraform.tfstate
aws s3 mv \
  s3://<terraform_state_bucket>/prd/03_compute_ecs/terraform.tfstate \
  s3://<terraform_state_bucket>/prd/04_compute_ecs/terraform.tfstate

cd terraform/aws/environments/prd/03_ecr
terraform init -backend-config=backend.hcl -reconfigure -migrate-state
cd ../04_compute_ecs
terraform init -backend-config=backend.hcl -reconfigure -migrate-state
cd ../05_cicd
terraform init -backend-config=backend.hcl -reconfigure
```

`04_compute_ecs` と `05_cicd` は remote state のキー参照が変わるため、上記のあと `terraform plan` で差分がないことを確認する。

## 操作例

### bootstrap

```bash
cd terraform/aws/bootstrap
terraform init
terraform apply
```

### 各スタック

各スタックは `backend.hcl` と `terraform.tfvars` を持つ。`terraform.tfvars` に `terraform_state_bucket` / `terraform_state_key_prefix` を設定する。

```bash
cd terraform/aws/environments/prd/00_iam
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

他スタックも同様に、対象ディレクトリで `init -backend-config=backend.hcl` → `plan` → `apply` を実行する。

state キー形式: `{terraform_state_key_prefix}/{スタック名}/terraform.tfstate`（例: `prd/01_network/terraform.tfstate`）

## 命名規則

| 対象 | 規則 | 例 |
|------|------|-----|
| Terraform 変数・モジュール引数 | `snake_case` | `container_port`, `host_port` |
| Terraform リソース属性（AWS provider） | provider 定義に従う | `container_port`（`aws_ecs_service.load_balancer`） |
| AWS API / JSON ペイロード | AWS 側のキー名 | `containerPort`, `hostPort`（タスク定義 JSON 内） |

Terraform 変数は `snake_case` に統一する。AWS API が camelCase を要求する箇所（ECS タスク定義 JSON など）のみ、リソースブロック内で AWS 形式を使う。

## モジュール

| モジュール | 用途 |
|------------|------|
| `networking` | VPC、サブネット、IGW、ルート |
| `nat_gateway` | NAT Gateway、プライベート RT へのデフォルトルート |
| `sg` | EC2/RDS 用 web・db SG、ECS/ALB 用 SG |
| `iam` | EC2 インスタンスプロファイル、ECS タスク実行ロール |
| `ec2` | EC2 インスタンス |
| `ecs` | ECS クラスター、Fargate サービス、ALB、スタンドアロンタスク |
| `rds` | RDS PostgreSQL |
| `ecr` | ECR リポジトリ（`03_ecr` スタック） |
| `codecommit` / `codebuild` / `codepipeline` | CI/CD パイプライン（`05_cicd` スタック） |
| `eip` | Elastic IP（未接続） |
