output "docdb_endpoint" {
  value = aws_docdb_cluster.this.endpoint
}

output "docdb_port" {
  value = aws_docdb_cluster.this.port
}
