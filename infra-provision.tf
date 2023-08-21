provider "aws" {
  region = "us-east-1"
  profile = "jenny"
}
# VPC and Subnet for Fargate (assuming you don't have existing ones to use)
resource "aws_vpc" "dev_vpc" {
  cidr_block = "10.0.0.0/16"
}
resource "aws_subnet" "dev_subnet" {
  vpc_id     = aws_vpc.dev_vpc.id
  cidr_block = "10.0.1.0/24"
}
# ECS Cluster
resource "aws_ecs_cluster" "ping" {
  name = "ping"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}
# ECS Task Definition for Fargate
resource "aws_ecs_task_definition" "task" {
  family                        = "service"
  network_mode                  = "awsvpc"
  requires_compatibilities      = ["FARGATE", "EC2"]
  cpu                           = 512
  memory                        = 2048
  container_definitions         = jsonencode([
    {
      name      = "nginx-app"
      image     = "nginx:latest"
      cpu       = 512
      memory    = 2048
      #essential = true  # if true and if fails, all other containers fail. Must have at least one essential
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}
# ECS Service for Fargate
resource "aws_ecs_service" "service_1" {
  name              = "service1"
  cluster           = aws_ecs_cluster.ping.id
  task_definition   = aws_ecs_task_definition.task.id
  desired_count     = 1
  launch_type       = "FARGATE"
  platform_version  = "LATEST"

  network_configuration {
    #assign_public_ip  = true
    subnets = [aws_subnet.dev_subnet.id]
  }
}
resource "aws_ecs_service" "service_2" {
  name              = "service2"
  cluster           = aws_ecs_cluster.ping.id
  task_definition   = aws_ecs_task_definition.task.id
  desired_count     = 1
  launch_type       = "FARGATE"
  platform_version  = "LATEST"

  network_configuration {
    #assign_public_ip  = true
    subnets = [aws_subnet.dev_subnet.id]
  }
}
# DynamoDB Tables
resource "aws_dynamodb_table" "cash_events_dev" {
  name           = "cash-events-dev"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id" # Adjust as per your schema

  attribute {
    name = "id"
    type = "S"
  }
}
resource "aws_dynamodb_table" "card_events_dev" {
  name           = "card-events-dev"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id" # Adjust as per your schema
  attribute {
    name = "id"
    type = "S"
  }
}
# IAM Role for ECS Task Execution with Fargate
resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs_execution_role"
  assume_role_policy = jsonencode({

    Version = "2012-10-17",

    Statement = [

      {

        Action = "sts:AssumeRole",

        Principal = {

          Service = "ecs-tasks.amazonaws.com"

        },

        Effect = "Allow",

        Sid    = ""

      }

    ]

  })

}

 

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy_attachment" {

  role       = aws_iam_role.ecs_execution_role.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"

}
