# AWS Terraform

`ap-northeast-1` 向けの Terraform 構成。`bootstrap/` でリモートステート基盤を作成し、`environments/prd/` を番号付きスタックに分割して管理する。

## ディレクトリ構成

| パス | 内容 |
|------|------|
| `bootstrap/` | リモートステート用 S3 バケット・DynamoDB ロックテーブル（初回のみ） |
| `modules/` | 再利用モジュール（VPC、SG、EC2、ECS、RDS、IAM、CI/CD など） |
| `environments/prd/` | 本番想定スタック（スタックごとに独立した state） |

## AWS 構成図（prd）

リージョン `ap-northeast-1`。VPC `192.168.0.0/16` は `01_network`、NAT は任意の `01_network_nat`。

```mermaid
flowchart TB
  subgraph ext["外部"]
    user[利用者 / 管理者]
    gha[GitHub Actions]
  end

  subgraph mgmt["bootstrap（VPC 外）"]
    s3[(S3\nTerraform State)]
    lock[(DynamoDB\nState Lock)]
  end

  subgraph region["ap-northeast-1"]
    subgraph vpc["VPC 192.168.0.0/16"]
      igw[Internet Gateway]

      subgraph public["パブリックサブネット（1a / 1c）"]
        alb[ALB :80\n04_compute_ecs]
        ec2[EC2 + web-sg\n03_compute_ec2]
        nat[NAT Gateway\n01_network_nat 任意]
      end

      subgraph private["プライベートサブネット（1a / 1c）"]
        rds[(RDS MySQL\n02_database)]
        ecs[ECS Fargate Service\n04_compute_ecs]
        vpce[VPC Endpoints\n03_ecr]
      end
    end

    ecr[ECR リポジトリ\n03_ecr]
    iam_ec2[EC2 Instance Profile\nSSM 等]
    iam_ecs[ECS Task / Execution Role]
    oidc[GitHub Actions OIDC Role\n05_cicd]
    logs[CloudWatch Logs]
  end

  user -->|HTTP/HTTPS| igw
  user -->|SSH| igw
  igw --> alb
  igw --> ec2
  nat -.->|0.0.0.0/0 任意| igw
  nat -.-> private

  alb -->|ターゲットグループ| ecs
  ec2 -->|3306 db-sg| rds

  ecs --> vpce
  vpce --> ecr
  ecs --> logs

  ec2 --- iam_ec2
  ecs --- iam_ecs

  gha -->|AssumeRoleWithWebIdentity| oidc
  oidc -->|push| ecr
  oidc -->|RegisterTaskDefinition / UpdateService| ecs
```

| 配置 | リソース | スタック |
|------|----------|----------|
| パブリック | ALB、EC2（`use_database_security_groups=true` 時は `02_database` の web-sg） | `04_compute_ecs` / `03_compute_ec2` |
| プライベート | RDS、ECS タスク（`assign_public_ip=false`）、VPC Endpoint（ECR API/DKR、Logs、ECS、S3 Gateway） | `02_database` / `04_compute_ecs` / `03_ecr` |
| VPC 外・グローバル | ECR、IAM ロール、GitHub OIDC、Terraform state | `03_ecr` / `00_iam` / `05_cicd` / `bootstrap` |

プライベートサブネットの ECS は `03_ecr` の VPC Endpoint 経由でイメージ取得可能（NAT なし運用向け）。NAT が必要な外向き通信は `01_network_nat` を追加する。

## スタック一覧

| スタック | パス | 主なリソース | 参照する remote state |
|----------|------|--------------|------------------------|
| bootstrap | `bootstrap/` | S3（state）、DynamoDB（lock） | なし |
| 00_iam | `environments/prd/00_iam/` | EC2 用 IAM ロール、ECS タスク実行ロール | なし |
| 01_network | `environments/prd/01_network/` | VPC、サブネット、IGW、ルート（プライベートは NAT なし） | なし |
| 01_network_nat | `environments/prd/01_network_nat/` | NAT Gateway、プライベート RT への 0.0.0.0/0（任意） | `01_network` |
| 02_database | `environments/prd/02_database/` | RDS、web/db 用 SG | `01_network` |
| 03_compute_ec2 | `environments/prd/03_compute_ec2/` | EC2 | `00_iam`, `01_network`, （任意）`02_database` |
| 03_ecr | `environments/prd/03_ecr/` | ECR リポジトリ、ECS 向け VPC Endpoint（Interface + S3 Gateway） | `01_network` |
| 04_compute_ecs | `environments/prd/04_compute_ecs/` | ECS（Fargate ARM64）常駐 Service + ALB、ECS/ALB 用 SG | `00_iam`, `01_network`, `03_ecr` |
| 04_compute_ecs_task | `environments/prd/04_compute_ecs_task/` | 単発 ECS タスク定義（手動 run-task / 任意スケジュール）。ALB なし | `00_iam`, `01_network`, `03_ecr`, `04_compute_ecs` |
| 05_cicd | `environments/prd/05_cicd/` | GitHub Actions OIDC（ECR push / ECS deploy 用 IAM ロール） | `00_iam`, `03_ecr`, `04_compute_ecs`（outputs 参照） |

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
  ecs_task[04_compute_ecs_task]
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
  network --> ecr
  iam --> ec2
  iam --> ecs
  iam --> cicd
  database -->|use_database_security_groups=true 時| ec2
  ecr --> ecs
  ecr --> ecs_task
  ecr --> cicd
  ecs --> ecs_task
  ecs --> cicd
```

## apply 順

1. **bootstrap**（アカウント初回のみ）
2. **00_iam** と **01_network**（相互依存なし。並列可）
3. **01_network_nat**（プライベートからインターネット egress が必要なときのみ。`01_network` 完了後）
4. **02_database**（`01_network` 完了後）
5. **03_compute_ec2** と **03_ecr**（`01_network` 完了後。EC2 は `00_iam` も必要。EC2 と ECR は相互依存なし。並列可）
   - EC2 で `use_database_security_groups = true` の場合は **02_database** も先に apply すること
6. **04_compute_ecs**（`00_iam` + `01_network` + **03_ecr** 完了後。イメージ tag が ECR に存在すること）
7. **04_compute_ecs_task**（任意。`04_compute_ecs` 完了後。単発タスクのみ必要なとき）
8. **05_cicd**（`04_compute_ecs` と `03_ecr` 完了後。GitHub → ECR → ECS Service の順は従来どおり）

destroy は上記の逆順。

## apply（コピペ用 / Makefile）

前提として、`make init-bootstrap` と `make init-all`（または各スタックの `make init STACK=...`）で init 済みであること。

```bash
cd terraform/aws

make apply STACK=bootstrap
make apply STACK=00_iam
make apply STACK=01_network
make apply STACK=01_network_nat
make apply STACK=02_database
make apply STACK=03_compute_ec2
make apply STACK=03_ecr
make apply STACK=04_compute_ecs
make apply STACK=04_compute_ecs_task
make apply STACK=05_cicd
```

`EXTRA_ARGS` で `terraform apply` に引数を渡せる（例: `EXTRA_ARGS="-auto-approve"`）。

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
| `vpc_endpoints_ecs` | プライベートサブネット向け ECR / Logs / ECS / S3 VPC Endpoint（`03_ecr` スタック） |
| `github_actions_oidc` | GitHub Actions からの OIDC 連携 IAM（`05_cicd` スタック） |
| `eip` | Elastic IP（未接続） |
