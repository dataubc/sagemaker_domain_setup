resource "aws_default_vpc" "poc_vpc" {
	tags = {
		Name = "sageMakerVPC"
	}
}

resource "aws_default_subnet" "poc_subnet" {
	availability_zone = "ca-central-1b" # 
	tags = {
		Name = "Default subnet for ca-central-1"
	}
}

resource "aws_default_security_group" "poc_security_group" {
  vpc_id = aws_default_vpc.poc_vpc.id

  ingress {
    protocol    = -1
    self        = true
    from_port   = 0
    to_port     = 0
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_default_subnet.poc_subnet.cidr_block]
  }
}
