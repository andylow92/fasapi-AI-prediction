provider "aws" {
  region = "your-aws-region"
}

resource "aws_cloudwatch_log_group" "my_log_group" {
  name = "/aws/ec2/my-fastapi-app"  # Name of the log group

  # Optionally, specify how long you want logs to be retained. If omitted, logs are retained indefinitely.
  # The retention period is specified in days. Common values are 30, 90, 180, and 365.
  retention_in_days = 90

  # Optionally, add tags to the log group
  tags = {
    Environment = "production"
    Project     = "My FastAPI App"
  }
}

resource "aws_iam_policy" "ec2_policy" {
  name   = "ec2_policy"
  path   = "/"
  description = "EC2 policy for accessing ECR and CloudWatch"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
       Resource = "${aws_cloudwatch_log_group.my_log_group.arn}:*"  # This uses the ARN of the Log Group created above
      }
    ]
  })
}

resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_policy_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_policy.arn
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "EC2InstanceProfile"
   role = aws_iam_role.ec2_role.name 
}

resource "aws_instance" "app_instance" {
  ami           = "ami-00381a880aa48c6c6"  # Update this with the correct AMI for your region, typically an Ubuntu Server AMI
  instance_type = "t3.micro"
  key_name      = "name-of-your-key"      # Replace with your SSH key name, you should previusly create one if you have not do it

  security_groups = ["${aws_security_group.app_sg.name}"]
  # Associate the instance profile
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
user_data = <<-EOF
              #!/bin/bash
              # Update and install necessary packages
              sudo apt update
              sudo apt install -y docker.io
              sudo systemctl start docker
              sudo systemctl enable docker

              # Install AWS CLI
              cd /tmp
              sudo apt install -y unzip
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              sudo ./aws/install
              
              # Pull and run your Docker container
              aws ecr get-login-password --region your-region| docker login --username AWS --password-stdin your-aws-account-id.dkr.ecr.your-region.amazonaws.com/
              sudo docker pull your-aws-account-id.dkr.ecr.your-region.amazonaws.com/your-repo-name:your-tag
              sudo docker run -d -p 8000:8000 your-aws-account-id.dkr.ecr.your-region.amazonaws.com/your-repo-name:your-tag
              EOF

  tags = {
    Name = "FastAPI-App-Server"
  }
}

resource "aws_security_group" "app_sg" {
  name        = "fastapi_app_sg"
  description = "Allow web traffic to FastAPI app"
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    # Add this block to allow SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["your-ip/32"]
  }

    # Add this block to allow access to FastAPI on port 8000
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["your-ip/32"] # Adjust this to restrict access if necessary
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
