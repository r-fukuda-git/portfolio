output "codecommit_repository_name" {
  value = module.codecommit.repository_name
}

output "codecommit_clone_url_http" {
  value = module.codecommit.clone_url_http
}

output "codecommit_clone_url_ssh" {
  value = module.codecommit.clone_url_ssh
}

output "codebuild_project_name" {
  value = module.codebuild.project_name
}

output "codepipeline_name" {
  value = module.codepipeline.pipeline_name
}

output "pipeline_artifact_bucket_name" {
  value = aws_s3_bucket.pipeline_artifacts.bucket
}
