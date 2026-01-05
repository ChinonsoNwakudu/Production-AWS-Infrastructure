output "eks_endpoint" {
  value = aws_eks_cluster.prod.endpoint
}

/* output "alb_dns" {
  value = aws_lb.app_alb.dns_name
} */