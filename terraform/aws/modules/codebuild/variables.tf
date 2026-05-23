variable "env" {
  type = string
}

variable "project_name" {
  type = string
}

variable "description" {
  type    = string
  default = "Build container image and produce ECS imagedefinitions.json"
}

variable "artifact_bucket_arn" {
  type = string
}

variable "ecr_repository_name" {
  type = string
}

variable "container_name" {
  type        = string
  description = "ECS task container name referenced in imagedefinitions.json"
}

variable "dockerfile_path" {
  type        = string
  description = "Dockerfile path relative to repository root"
  default     = "Dockerfile"
}

variable "build_context" {
  type        = string
  description = "Docker build context path relative to repository root"
  default     = "."
}

variable "buildspec" {
  type        = string
  description = "CodeBuild buildspec document"
  default     = <<-EOT
    version: 0.2

    phases:
      pre_build:
        commands:
          - echo Logging in to Amazon ECR...
          - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
      build:
        commands:
          - echo Build started on `date`
          - docker build -t $IMAGE_REPO_NAME:$CODEBUILD_RESOLVED_SOURCE_VERSION -f $DOCKERFILE_PATH $BUILD_CONTEXT
          - docker tag $IMAGE_REPO_NAME:$CODEBUILD_RESOLVED_SOURCE_VERSION $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$CODEBUILD_RESOLVED_SOURCE_VERSION
          - docker tag $IMAGE_REPO_NAME:$CODEBUILD_RESOLVED_SOURCE_VERSION $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:latest
      post_build:
        commands:
          - echo Build completed on `date`
          - docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$CODEBUILD_RESOLVED_SOURCE_VERSION
          - docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:latest
          - printf '[{"name":"%s","imageUri":"%s"}]' "$CONTAINER_NAME" "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$CODEBUILD_RESOLVED_SOURCE_VERSION" > imagedefinitions.json
          - cat imagedefinitions.json

    artifacts:
      files:
        - imagedefinitions.json
  EOT
}

variable "compute_type" {
  type    = string
  default = "BUILD_GENERAL1_SMALL"
}

variable "build_image" {
  type    = string
  default = "aws/codebuild/standard:7.0"
}

variable "build_timeout" {
  type    = number
  default = 20
}

variable "log_retention_in_days" {
  type    = number
  default = 14
}
