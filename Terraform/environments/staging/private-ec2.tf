module "private-security-group" {
  source  = "../../modules/security-groups"
  sg_name = "private-sg"
  vpc_id  = module.staging_vpc.id
  ingress_rules = [
    {
      description = "description"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [module.public-security-group.id]
    }
  ]

  environment = "Staging"
  createdBy   = "Terraform"
}

module "public-ec2" {
  source                 = "../../modules/ec2"
  instance_type          = "t3.nano"
  monitoring             = true
  key_name               = module.keypair.private_key
  subnet_id              = module.staging_vpc.public_subnets[0]
  vpc_security_group_ids = [module.public-security-group.id]
  environment            = "Staging"
  createdBy              = "Terraform"
}
