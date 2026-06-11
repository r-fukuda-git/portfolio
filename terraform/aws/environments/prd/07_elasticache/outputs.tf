output "cluster_id" {
  value = module.elasticache.cluster_id
}

output "cluster_arn" {
  value = module.elasticache.cluster_arn
}

output "cache_nodes" {
  value = module.elasticache.cache_nodes
}

output "security_group_id" {
  value = module.elasticache.security_group_id
}
