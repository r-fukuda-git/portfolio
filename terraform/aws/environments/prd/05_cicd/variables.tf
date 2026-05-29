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
