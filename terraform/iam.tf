  resource "aws_security_group" "nodeport_access" {
    name        = "nodeport_access"
    description = "Allow NodePort access to frontend and backend"
  
    ingress {
      description = "Allow NodePort access to frontend"
      from_port   = 30080
      to_port     = 30080
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  
    ingress {
      description = "Allow NodePort access to backend"
      from_port   = 30081
      to_port     = 30081
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
