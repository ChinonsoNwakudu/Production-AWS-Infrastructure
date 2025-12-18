resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/ec2/app"
  retention_in_days = 30
  tags              = var.project_tags
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  alarm_actions       = [] # Add SNS topic ARN for alerts
  dimensions = {
    AutoScalingGroupName = var.asg_name
  }
  tags = var.project_tags
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "Prod-Dashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.asg_name]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "EC2 CPU"
        }
      }
    ]
  })
}

resource "aws_budgets_budget" "monthly" {
  name         = "monthly-budget"
  budget_type  = "COST"
  limit_amount = "10"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = ["nwakudue@gmail.com"]
  }
}