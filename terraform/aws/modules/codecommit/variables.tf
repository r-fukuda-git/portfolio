variable "env" {
  type = string
}

variable "project_name" {
  type = string
}

variable "repository_suffix" {
  type        = string
  description = "Suffix appended to the repository name"
  default     = "app"
}

variable "description" {
  type        = string
  description = "CodeCommit repository description"
  default     = "Application source repository"
}
