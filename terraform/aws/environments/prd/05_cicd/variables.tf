variable "env" {
  type = string
}

variable "project_name" {
  type = string
}

variable "github_owner" {
  type        = string
  description = "GitHub organization or user (OIDC subject repo owner)"
}

variable "github_repository" {
  type        = string
  description = "GitHub repository name"
}

variable "dev_branch" {
  type    = string
  default = "dev"
}

variable "main_branch" {
  type    = string
  default = "main"
}

variable "go_module_path" {
  type        = string
  description = "Path to Go module relative to repository root (used in workflow documentation)"
  default     = "golang/cicd-demo"
}

variable "dockerfile_path" {
  type        = string
  description = "Dockerfile path relative to repository root (used in workflow documentation)"
  default     = "golang/cicd-demo/Dockerfile"
}

variable "build_context" {
  type        = string
  description = "Docker build context relative to repository root"
  default     = "golang/cicd-demo"
}
