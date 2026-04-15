#lookup for the default vpc
data "aws_vpc" "default_vpc" {
  default = true
}

# subnet list in the default vpc
# the default vpc has all pub subnets
data "aws_subnet_ids" "default_public" {
  vpc_id = data.aws_vpc.default_vpc.id
}
