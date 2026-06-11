output "cluster_id" {
  value = aws_elasticache_cluster.this.cluster_id
}

output "cluster_arn" {
  value = aws_elasticache_cluster.this.arn
}

output "cache_nodes" {
  value = aws_elasticache_cluster.this.cache_nodes
}

output "configuration_endpoint" {
  value = aws_elasticache_cluster.this.configuration_endpoint
}

output "security_group_id" {
  value = aws_security_group.cache.id
}
